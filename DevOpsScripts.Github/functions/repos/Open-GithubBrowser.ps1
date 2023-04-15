<#
    .SYNOPSIS
    Open a github repository in the browser.

    .DESCRIPTION
    Open a github repository in the browser.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .EXAMPLE

    Open a the repository on the current path in the Browser:

    PS> Open-GithubBrowser

    .EXAMPLE

    Open a specific repository in the current Context in the Browser:

    PS> Open-GithubBrowser <autocomplete_repo>

    .EXAMPLE

    Open a repository in another Context in the Browser:

    PS> Open-GithubBrowser -Context <autocomplete_context> <autocomplete_repo>

    .LINK
        
#>

function Open-GithubBrowser {

    [Alias('gitbrowser')]
    param (
        # The Name of the Github Repository.
        [Parameter(
            Mandatory = $false,
            Position = 0
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
                $Context = Get-GithubContextInfo -Context $fakeBoundParameters['Context']
                $validValues = $Context.repositories.Name

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
        $Context
    )

    $repository = Get-GithubRepositoryInfo -Context $Context -Name $Name
    Start-Process $repository.html_url

}