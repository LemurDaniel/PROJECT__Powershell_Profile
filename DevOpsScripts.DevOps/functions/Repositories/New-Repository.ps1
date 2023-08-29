
<#
    .SYNOPSIS
    Create a new Repository in the current organization and project.

    .DESCRIPTION
    Create a new Repository in the current organization and project.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    return a list of all repository refs.


    .LINK
        
#>

function New-Repository {

    [CmdletBinding()]
    param ( 
        # The name of the Project to swtich to in which you want to open a repository. Will default to curren tproject context.
        [Parameter(
            Mandatory = $false,
            Position = 1
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
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Project,

        # The name of the newley created repository
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [System.String]
        $Name
    )  


    $projectInfo = Get-ProjectInfo -Name $Project
    $Request = @{
        Project = $projectInfo.name
        METHOD  = 'POST'
        API     = "/_apis/git/repositories?api-version=7.0"
        body    = @{
            name    = $Name
            project = @{
                id = $projectInfo.id
            }
    
            # TODO maybe when forking
            # parentRepository = @{
            #     name    = $Name
            #     project = @{
            #         name = $Project
            #     }
            # }
              
        }
    }
    
    $null = Invoke-DevOpsRest @Request 
    $projectInfo = Get-ProjectInfo -Name $Project -Refresh
    return Open-Repository -Project $ProjectInfo.name -Name $Name
}
