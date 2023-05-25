
<#
    .SYNOPSIS
    Get buildlogs for a pipeline run and saves them to files.

    .DESCRIPTION
    Get buildlogs for a pipeline run and saves them to files.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .LINK
        
#>
function Get-BuildLogs {
    
    [cmdletbinding(
        DefaultParameterSetName = 'currentContext'
    )]
    param (
        # The name of the Project to swtich to in which you want to open a repository. Will default to curren tproject context.
        [Parameter(
            ParameterSetName = 'Projectspecific',
            Mandatory = $false,
            Position = 2
        )]   
        [ValidateScript(
            { 
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-DevOpsProjects).name
            },
            ErrorMessage = 'Please specify a correct Projectname.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-DevOpsProjects).name 
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Project,

        # The Name of the Pipeline in the Current Project.
        [Parameter(
            ParameterSetName = 'Projectspecific',
            Mandatory = $true,
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'currentContext',
            Mandatory = $false,
            Position = 0
        )]   
        [ValidateScript(
            { 
                # NOTE cannot access Project when changes dynamically with tab-completion
                $true 
            },
            ErrorMessage = 'Please specify an correct Name.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = Get-DevOpsPipelines -Project $fakeBoundParameters['Project']
                
                $validValues.name | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Pipeline,



        # The offset to the last run. 0 gets the latest, -1 is the first behind latest, etc.
        [Parameter(
            Mandatory = $false
        )]
        $lastRun = 0,


        # The output folder, where to save the downloaded logs
        [Parameter(
            Mandatory = $true
        )]
        $outFolder
    )

    $Project = Get-ProjectInfo -Name $Project | Select-Object -ExpandProperty name
    $PipelineId = Get-DevOpsPipelines -Project $Project 
    | Where-Object -Property name -EQ -Value $Pipeline
    | Select-Object -ExpandProperty id


    $Request = @{
        Project = $Project
        Method  = 'GET'
        SCOPE   = 'PROJ'
        API     = "/_apis/pipelines/$PipelineId/runs?api-version=7.0"
    }
    $pipelineRun = Invoke-DevOpsRest @Request
    | Select-Object -ExpandProperty value 
    | Select-Object -Skip $lastRun -First 1


    if (!(Test-Path $outFolder)) {
        $null = New-Item -ItemType Directory -Path $outFolder 
    }

    $folder = New-Item -ItemType Directory -Path "$outFolder/$Pipeline/run-$($pipelineRun.id)" -Force



    $Progress = @{
        Id              = Get-Random -Maximum 256
        Activity        = 'Download Log'
        PercentComplete = 0
        Status          = ""
    }
    $Request = @{
        Project = $Project
        Method  = 'GET'
        SCOPE   = 'PROJ'
        API     = "/_apis/pipelines/$PipelineId/runs/$($pipelineRun.id)/logs?api-version=7.0"
    }
    $buildLogs = Invoke-DevOpsRest @Request | Select-Object -ExpandProperty logs

    $buildLogs | ForEach-Object {

        $Progress.Status = "$($_.id) / $($buildLogs.Count)"
        $Progress.PercentComplete = $_.id / $buildLogs.Count * 100
        Write-Progress @Progress
        $Request = @{
            Project = $Project
            Method  = 'GET'
            SCOPE   = 'PROJ'
            API     = "/_apis/pipelines/$PipelineId/runs/$($pipelineRun.id)/logs/$($_.id)?api-version=7.0"
            Query   = @{
                "`$expand" = "signedContent"
            }
        }
        $logInfo = Invoke-DevOpsRest @Request
        $filename = [System.String]::Format("{0}/{1:00}.log", $($folder.FullName), $logInfo.id)

        Invoke-RestMethod -Method GET -Uri $logInfo.signedContent.url
        | Out-File -FilePath $filename
    }

    Write-Progress @Progress -Completed

}