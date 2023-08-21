
<#
    .SYNOPSIS
    Get buildlogs for a pipeline run and saves them to files.

    .DESCRIPTION
    Get buildlogs for a pipeline run and saves them to files.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    [System.IO.DirectoryInfo] of folder containing logs.

    .EXAMPLE

    Download the logs for a Pipeline in the current Project-Context:

    Get-BuildLogs -Pipeline <autocompleted_name>

    .EXAMPLE

    Download the logs for a Pipeline in a project and open the  Folder:

    Get-BuildLogs -Project <autocompleted_project> -Pipeline <autocompleted_name> -openFolder

    .EXAMPLE

    Download the logs for the third-last run of a Pipeline in a project to a specific Folder:

    Get-BuildLogs -Project <autocompleted_project> -Pipeline <autocompleted_name> -outFolder './logs' -Skip 3

    .LINK
        
#>
function Get-BuildLogs {
    
    [cmdletbinding(
        DefaultParameterSetName = 'currentContext',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param (
        # The name of the Project to swtich to in which you want to open a repository. Will default to curren tproject context.
        [Parameter(
            ParameterSetName = 'Projectspecific',
            Mandatory = $false,
            Position = 1
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
                $validValues = (Get-OrganizationInfo).projects.name
                
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

        # The output folder, where to save the downloaded logs
        [Parameter(
            Mandatory = $false,
            Position = 2
        )]
        [System.String]
        $outFolder = '.',

        # The offset to the last run. 0 gets the latest, 1 is the first behind latest, etc.
        [Parameter(
            Mandatory = $false,
            Position = 3
        )]
        [System.Int32]
        $Skip = 0,


        # Open the folder with the logs in the Explorer.
        [Parameter(
            Mandatory = $false,
            Position = 4
        )]
        [switch]
        $OpenFolder
    )

    # Get Project and Pipeline
    $Project = Get-ProjectInfo -Name $Project | Select-Object -ExpandProperty name
    $PipelineId = Get-DevOpsPipelines -Project $Project 
    | Where-Object -Property name -EQ -Value $Pipeline
    | Select-Object -ExpandProperty id


    # Get Pipeline runs
    $Request = @{
        Project = $Project
        Method  = 'GET'
        SCOPE   = 'PROJ'
        API     = "/_apis/pipelines/$PipelineId/runs?api-version=7.0"
    }
    $pipelineRun = Invoke-DevOpsRest @Request
    | Select-Object -ExpandProperty value 
    | Select-Object -Skip $skip -First 1



    # Create basefolder if necessery
    if (!(Test-Path $outFolder)) {
        $null = New-Item -ItemType Directory -Path $outFolder 
    }

    # Check if run was already downloaded and ask for confirmation
    $folderPath = "$outFolder/_logs-$Project/$Pipeline/run-$($pipelineRun.id)"
    if (Test-Path $folderPath) {
        if ($PSCmdlet.ShouldProcess($folderPath, "Replace existing logs in directory")) {
            Remove-Item -Path $folderPath -Recurse
        }
        else {
            return Get-Item -Path $folderPath
        }
    }
    
    # Create folder, open when needed
    $folder = New-Item -ItemType Directory -Path $folderPath -Force
    if ($OpenFolder) {
        Start-Process -FilePath $folder.FullName
    }

    # Download logs from run
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

    # Download Content of each logfile, plus progress bar.
    for ($index = 0; $index -lt $buildLogs.Count; $index++) {

        $logInfo = $buildLogs[$index]
        $Progress.PercentComplete = [System.Math]::Round($index / $buildLogs.Count * 100)
        $Progress.Status = "$($logInfo.id) / $($buildLogs.Count) - ($($Progress.PercentComplete)%)"
        Write-Progress @Progress
        $Request = @{
            Project = $Project
            Method  = 'GET'
            SCOPE   = 'PROJ'
            API     = "/_apis/pipelines/$PipelineId/runs/$($pipelineRun.id)/logs/$($logInfo.id)?api-version=7.0"
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

    return $folder
}