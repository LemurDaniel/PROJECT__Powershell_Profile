<#
    .SYNOPSIS
    Gets all DevOps Pipelines in the Current Project.

    .DESCRIPTION
    Gets all DevOps Pipelines in the Current Project.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The DevOps Pipelines of the Current Project.


    .EXAMPLE

    Gets all Names of the DevOps Pipelines of the Current Project.

    PS> Get-DevOpsPipelines 'name'
    
    .LINK
        
#>
function Get-DevOpsPipelines {

    [cmdletbinding()]
    param(
        # The name of the Project to swtich to in which you want to open a repository. Will default to curren tproject context.
        [Parameter(
            Mandatory = $false,
            Position = 0
        )]   
        [ValidateScript(
            { 
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-OrganizationInfo).projects.name
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

        # The return Property
        [Parameter()]
        [System.String]
        $Property,

        # Switch to refresh the cache.
        [Parameter()]
        [switch]
        $Refresh
    )

    $projectInfo = Get-ProjectInfo -Name $Project
    $Pipelines = Get-AzureDevOpsCache -Type Pipeline -Identifier $projectInfo.id

    if (!$Pipelines -OR $Refresh) {
        # Get Pipelines.
        $Request = @{
            Project = $projectInfo.name
            Method  = 'GET'
            Domain  = 'dev.azure'
            SCOPE   = 'PROJ'
            API     = '_apis/pipelines?api-version=7.0'
        }
        $Pipelines = Invoke-DevOpsRest @Request -Property 'value'
        $Pipelines = Set-AzureDevOpsCache -Object $Pipelines -Type Pipeline -Identifier $projectInfo.id
    }

    return Get-Property -Object $Pipelines -Property $Property
}