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

    PS> gitbrowser


    .EXAMPLE

    Open a specific tab for the current repository:

    PS> gitbrowser -tab <autocompleted_tabs>


    .EXAMPLE

    Open a tab for a specific repository:

    PS> gitbrowser <autocomplete_repo> <autocompleted_tab>


    .EXAMPLE

    Open a tab for a specific repository in another account:

    PS> Open-GithubBrowser -Account <autocompleted_account> <autocomplete_repo> <autocompleted_tab>


    .EXAMPLE

    Open a tab in a repository in another Account and another Context in the current account:

    PS> Open-GithubRepository -Account <autocompleted_account> -Context <autocomplete_context> <autocomplete_repo> <autocompleted_tab>


    .EXAMPLE

    Open a tab in a repository in another Account and another context in another account:

    PS> Open-GithubRepository -Account <autocompleted_account> -Context <autocomplete_context> <autocomplete_repo> <autocompleted_tab>

    .LINK
        
#>

function Open-GithubBrowser {

    [Alias('gitbrowser')]
    param (
        [Parameter(
            Position = 3,
            Mandatory = $false
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-GithubAccountContext -ListAvailable).name
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [validateScript(
            {
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-GithubAccountContext -ListAvailable).name
            }
        )]
        [Alias('a')]
        $Account,

        # The Name of the Github Context to use. Defaults to current Context.
        [Parameter(
            Mandatory = $false,
            Position = 2
        )]
        #[ValidateScript(
        #    { 
        #        [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-GithubContexts).login
        #    },
        #    ErrorMessage = 'Please specify an correct Context.'
        #)]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
                $validValues = (Get-GithubContexts -Account $fakeBoundParameters['Account']).login
        
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        [Alias('c')]
        $Context,

        # The Name of the Github Repository.
        [Parameter(
            Mandatory = $false,
            Position = 0
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
                $Context = Get-GithubContextInfo -Account $fakeBoundParameters['Account'] -Context $fakeBoundParameters['Context']
                $validValues = $Context.repositories.Name

                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Name,


        [Parameter(
            Mandatory = $false,
            Position = 1
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = (Get-Content -Path "$PSScriptRoot/repository.tabs.json" | ConvertFrom-Json -AsHashtable).Keys

                $validValues
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-Content -Path "$PSScriptRoot/repository.tabs.json" | ConvertFrom-Json -AsHashtable).Keys
            }
        )]
        [Alias('t')]
        $Tab
    )

    $repository = Get-GithubRepositoryInfo -Account $Account -Context $Context -Name $Name

    if ($PSBoundParameters.ContainsKey('Tab')) {
        $urlPath = (Get-Content -Path "$PSScriptRoot/repository.tabs.json" | ConvertFrom-Json -AsHashtable)[$Tab]
        Start-Process "$($repository.html_url)$urlPath"
    }
    else {
        Start-Process $repository.html_url
    }

}