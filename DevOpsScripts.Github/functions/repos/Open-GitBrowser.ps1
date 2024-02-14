<#
    .SYNOPSIS
    Open a Git repository in the browser.

    .DESCRIPTION
    Open a Git repository in the browser.

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

    PS> Open-GitBrowser -Account <autocompleted_account> <autocomplete_repo> <autocompleted_tab>


    .EXAMPLE

    Open a tab in a repository in another Account and another Context in the current account:

    PS> Open-GitRepository -Account <autocompleted_account> -Context <autocomplete_context> <autocomplete_repo> <autocompleted_tab>


    .EXAMPLE

    Open a tab in a repository in another Account and another context in another account:

    PS> Open-GitRepository -Account <autocompleted_account> -Context <autocomplete_context> <autocomplete_repo> <autocompleted_tab>

    .LINK
        
#>

function Open-GitBrowser {

    [Alias('git-browser')]
    param (
        # The name of the Git account to use. Defaults to current Account.
        [Parameter(
            Position = 3,
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Account' })]
        [System.String]
        [Alias('a')]
        $Account,

        # The Name of the Git Context to use. Defaults to current Context.
        [Parameter(
            Mandatory = $false,
            Position = 2
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Context' })]
        [System.String]
        [Alias('c')]
        $Context,

        # The Name of the Git Repository. Defaults to current Repository.
        [Parameter(
            Mandatory = $false,
            Position = 0
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Repository' })]
        [System.String]
        [Alias('Name')]
        $Repository,

        [Parameter(
            Mandatory = $false,
            Position = 1
        )]
        [System.String]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Tab' })]
        [Alias('t')]
        $Tab
    )

    $repositoryData = Get-GitRepositoryInfo -Account $Account -Context $Context -Name $Repository

    if ($PSBoundParameters.ContainsKey('Tab')) {
        $urlPath = Get-GitRepositoryTabs -Name $Tab
        Start-Process "$($repositoryData.html_url)$urlPath"
    }
    else {
        Start-Process $repositoryData.html_url
    }

}