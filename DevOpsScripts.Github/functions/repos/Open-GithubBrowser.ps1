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
        # The name of the github account to use. Defaults to current Account.
        [Parameter(
            Position = 3,
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Account' })]
        [System.String]
        [Alias('a')]
        $Account,

        # The Name of the Github Context to use. Defaults to current Context.
        [Parameter(
            Mandatory = $false,
            Position = 2
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Context' })]
        [System.String]
        [Alias('c')]
        $Context,

        # The Name of the Github Repository. Defaults to current Repository.
        [Parameter(
            Mandatory = $false,
            Position = 0
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Repository' })]
        [System.String]
        [Alias('Name')]
        $Repository,

        [Parameter(
            Mandatory = $false,
            Position = 1
        )]
        [System.String]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Tab' })]
        [Alias('t')]
        $Tab
    )

    $repository = Get-GithubRepositoryInfo -Account $Account -Context $Context -Name $Name

    if ($PSBoundParameters.ContainsKey('Tab')) {
        $urlPath = Get-GithubRepositoryTabs -Name $Tab
        Start-Process "$($repository.html_url)$urlPath"
    }
    else {
        Start-Process $repository.html_url
    }

}