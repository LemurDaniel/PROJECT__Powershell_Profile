<#
    .SYNOPSIS
    Get Information about a Repository in a Context.

    .DESCRIPTION
    Get Information about a Repository in a Context.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Information about the Repository.

    .EXAMPLE

    Get Info about a Repository in the current path:

    PS> Get-GithubRepositoryInfo

    .EXAMPLE

    Get Info about a Repository in the current Context:

    PS> Get-GithubRepositoryInfo <autocomplete_repo>

    .EXAMPLE

    Get Info about a Repository in the another Context:

    PS> Get-GithubRepositoryInfo -Context <autocomplete_context> <autocomplete_repo>

    .LINK
        
#>

function Get-GithubRepositoryInfo {

    param(
        # The Name of the Github Repository.
        [Parameter(
            Mandatory = $false,
            Position = 0
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
                $Context = Get-GithubContextInfo -Context $fakeBoundParameters['Context']
                $validValues = $Context.repositories.name

                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Name,

        # The Name of the Github Context to use. Defaults to current Context.
        [Parameter(
            Mandatory = $false,
            Position = 1
        )]
        [ValidateScript(
            { 
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-GithubContexts).login
            },
            ErrorMessage = 'Please specify an correct Context.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-GithubContexts).login

                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Context,

        [Parameter()]
        [switch]
        $Refresh
    )

    if ([System.String]::IsNullOrEmpty($Name) -and [System.String]::IsNullOrEmpty($Context)) {

        $currentPath = Get-Location
        if (!(Test-IsRepository)) {
            throw "'$currentPath' is not a valid repositorypath."
        }
        $repoPath = git -C $currentPath rev-parse --show-toplevel
        $Name = $repoPath.split('/')[-1]
        $Context = $repoPath.split('/')[-2]

    }

    $repository = Get-GithubContextInfo -Context $Context -Refresh:$Refresh 
    | Select-Object -ExpandProperty repositories 
    | Where-Object -Property Name -EQ -Value $Name

    if ($null -eq $repository) {
        throw "Not Repository found for '$Name' in Context '$Context'"
    }

    return $repository

}
