<#
    .SYNOPSIS
    Gets Repository Info for a repository in the current project or a project in the current organization-Context.

    .DESCRIPTION
    Gets Repository Info for a repository in the current project or a project in the current organization-Context.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Full Repository info or a Sub-Property of it if 'Property' is set.


    .EXAMPLE

    Get the Full Output of the current Repository in which the command is run

    PS> Get-RepositoryInfo


    .EXAMPLE

    Get the id of a repository in the current Project.

    PS> Get-RepositoryInfo '<repository_name>' -return id


    .EXAMPLE

    Get the id of a repository in the current Organization Context.

    PS> Get-RepositoryInfo -Project '<autocompleted_projectname>' '<autocompleted_repository_name>' -return id


    .LINK
        
#>

function Get-RepositoryInfo {

    [CmdletBinding(
        DefaultParameterSetName = 'currentProjectContext'
    )]
    param ( 
        # The Name of the Project. If null will default to current Project-Context.
        [Parameter(
            Mandatory = $false,
            Position = 1,
            ParameterSetName = 'projectspecific'
        )]
        [ValidateScript(
            { 
                $null -eq $_ -OR [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-OrganizationInfo).projects.name
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

        # The Name of the Repository. If null will default to current repository where command is executed.
        [Parameter(
            Mandatory = $false,
            Position = 0,
            ParameterSetName = 'currentProjectContext'
        )]
        [Parameter(
            Mandatory = $false,
            Position = 0,
            ParameterSetName = 'projectspecific'
        )]
        [ValidateScript(
            { 
                $true #[System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-ProjectInfo repositories.name)
            },
            ErrorMessage = 'Please specify a correct Name.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
                
                $validValues = Get-ProjectInfo -Name $fakeBoundParameters['Project'] -return 'repositories.name'
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Name,

        # Optional Path to a repository
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'currentProjectContext'
        )]
        [System.String]
        $path,

        # Optional Id of a repository
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'currentProjectContext'
        )]
        [System.String]
        $id,

      
        # The Property to return from the items. If null will return full Properties.
        [Alias('return')]
        [Parameter()]
        [System.String]
        $Property,

        # Force API-Call and overwrite Cache
        [Parameter()]
        [switch]
        $Refresh
    )  

    if (![System.String]::IsNullOrEmpty($Name)) {
        $repository = Get-ProjectInfo -Name $Project -return 'repositories' -refresh:$Refresh | Where-Object -Property Name -EQ -Value $Name
    }
    elseif (![System.String]::IsNullOrEmpty($id)) {
        $repository = Get-ProjectInfo -Name $Project -return 'repositories' -refresh:$Refresh | Where-Object -Property Name -EQ -Value $Name
    }
    else {
        # Get Current repository from VSCode Terminal, if nothing is specified.
        $path = [System.String]::IsNullOrEmpty($path) ? (git rev-parse --show-toplevel) : $path
        $repoName = $path.split('/')[-1]
        $projectName = $path.split('/')[-2]

        $projectName = $projectName -in (Get-OrganizationInfo).projects.name? $projectName : $null
        $repository = Get-ProjectInfo -Name $projectName -return 'repositories' -refresh:$Refresh | Where-Object -Property Name -EQ -Value $repoName
        
        if ($repository) {
            $repository | Add-Member NoteProperty currentPath $path
        }
    }

    if (!$repository) {
        Throw "Repository '$($repoName)' not found in current Project '$(Get-ProjectInfo -Name $Project 'name')'"
    }

    return $repository | Get-Property -return $Property
}