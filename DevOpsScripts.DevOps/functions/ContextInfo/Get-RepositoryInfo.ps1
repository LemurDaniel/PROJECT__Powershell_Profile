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

    [CmdletBinding()]
    param ( 
        # The Name of the Repository. If null will default to current repository where command is executed.
        [Parameter(
            Mandatory = $false,
            Position = 0
        )]
        [ValidateScript(
            { 
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-ProjectInfo repositories.name)
            },
            ErrorMessage = 'Please specify an correct Name.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = Get-ProjectInfo repositories.name
                
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

      
        # The Property to return from the items. If null will return full Properties.
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
        $repository = Search-In $repositories -where 'name' -has $repoName
        
        if($repository){
            $repository | Add-Member NoteProperty currentPath $path
        }
    }

    if (!$repository) {
        Throw "Repository '$($repoName)' not found in current Project '$(Get-ProjectInfo 'name')'"
    }
    if(!$repository.currentPath){
        $repository | Add-Member NoteProperty currentPath $repository.LocalPath
    }

    return $repository | Get-Property -return $Property
}