<#
    .SYNOPSIS
    Gets Repository Info for a repository in the current project.

    .DESCRIPTION
    Gets Repository Info for a repository in the current project.

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


    .LINK
        
#>

function Get-RepositoryInfo {

    # The Name of the Target-Repository. If not specifed tries returning info about the repository the command is excuted in.
    [CmdletBinding()]
    param ( 
        [Parameter(
            Mandatory = $false,
            Position = 0
        )]
        [ValidateScript(
            { 
                $_ -in (Get-ProjectInfo 'repositories.name')
            },
            ErrorMessage = 'Please specify an correct Name.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = Get-ProjectInfo 'repositories.name' 
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Name,

        # Optional Path to a repository
        [Parameter()]
        [System.String]
        $path,

        # Optional Id of a repository
        [Parameter()]
        [System.String]
        $id,

        # The Property to return from the info. If not specified everything will be returned.
        [Alias('return')]
        [Parameter()]
        [System.String]
        $Property,

        # Force API-Call and overwrite Cache
        [Parameter()]
        [switch]
        $refresh
    )  


    $repositories = Get-ProjectInfo 'repositories' -refresh:$refresh
    if (![System.String]::IsNullOrEmpty($Name)) {
        $repository = $repositories | Where-Object -Property Name -EQ -Value $Name
    }
    elseif (![System.String]::IsNullOrEmpty($id)) {
        $repository = $repositories | Where-Object -Property id -EQ -Value $id
    }
    else {
        # Get Current repository from VSCode Terminal, if nothing is specified.
        $path = [System.String]::IsNullOrEmpty($path) ? (git rev-parse --show-toplevel) : $path
        $repoName = $path.split('/')[-1]
        $repository = Search-In $repositories -where 'name' -is $repoName
    }

    if (!$repository) {
        Throw "Repository '$($repoName)' not found in current Project '$(Get-ProjectInfo 'name')'"
    }

    return Get-Property -Object $repository -Property $Property
}