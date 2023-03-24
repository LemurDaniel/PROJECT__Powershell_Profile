
<#
    .SYNOPSIS
    Creates a new Pipeline in Azure DevOps.

    .DESCRIPTION
    Creates a new Pipeline in Azure DevOps.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .LINK
        
#>
function New-Pipeline {
    
    [cmdletbinding()]
    param (
        # The name of the Project where to create the Pipeline. Defaults to current Context.
        [Parameter(
            Mandatory = $false
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

        # The Name of the newly created pipeline. 
        [Parameter(
            Mandatory = $true
        )]   
        [System.String]
        $Name,

        # The Folder of the newly created pipeline. 
        [Parameter(
            Mandatory = $true
        )]   
        [System.String]
        $Folder,

        # The Definitionpath for Pipelins of type yaml. 
        [Parameter(
            Mandatory = $true
        )]   
        [System.String]
        $definitionPath,

        # The Repository where yaml definition resides.
        [Parameter(
            Mandatory = $true
        )]   
        [System.String]
        $repositoryName,

        # The Source type of the pipeline. #TODO 
        [Parameter(
            Mandatory = $true
        )]
        [ValidateSet(
            'yaml'
        )]
        [System.String]
        $type = 'yaml',

        # Switch to open the repository in the Browser.
        [Parameter(
            Mandatory = $true
        )]
        [switch]
        $openBrowser
    )

    $repository = Get-RepositoryInfo -Project $Project -Name $RepositoryName
    $Request = @{
        Project = $Project
        Method  = 'POST'
        SCOPE   = 'PROJ'
        API     = '/_apis/pipelines?api-version=7.0'
        Body    = @{
            name          = $Name
            folder        = $Folder
            configuration = @{
                type       = $type
                path       = $definitionPath
                repository = @{
                    id   = $repository.id
                    type = 'azureReposGit'
                }
            }
        }
    }
                
    Invoke-DevOpsRest @Request

}
