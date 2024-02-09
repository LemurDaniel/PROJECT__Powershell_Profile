<#
    .SYNOPSIS
    Downloads and opens a Github-Repository by current Context or specified.

    .DESCRIPTION
    Downloads and opens a Github-Repository by current Context or specified.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Path to the Repository

    .EXAMPLE

    Open a repository in the current Context:

    PS> Open-GithubRepository <autocomplete_repo>

    .EXAMPLE

    Open a repository in the current Context:

    PS> Open-GithubRepository <autocomplete_repo> -CodeEditor 'Visual Studio'

    .EXAMPLE

    Open a repository in another Context:

    PS> Open-GithubRepository -Context <autocomplete_context> <autocomplete_repo>

    .EXAMPLE

    Open a repository in another Account and another Context:

    PS> Open-GithubRepository -Account <autocompleted_account> -Context <autocomplete_context> <autocomplete_repo>

    .LINK
        
#>

function Open-GithubRepository {

    [Alias('gitvc')]
    [cmdletbinding(
        SupportsShouldProcess,
        ConfirmImpact = 'high'
    )]
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

        # The Name of the Code Editor to use. Default to default.
        [Parameter(
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'CodeEditor' })]
        [System.String]
        $CodeEditor,


        # Only open the repository in the browser.
        [Parameter()]
        [switch]
        $Browser,

        # Only Download the Repository without opening it.
        [Parameter()]
        [switch]
        $onlyDownload,

        # Optional to replace an existing repository at the location and redownload it.
        [Parameter()]
        [switch]
        $replace
    )

    $user = Get-GithubUser -Account $Account
    $accountContext = Get-GithubAccountContext -Account $Account
    $repository = Get-GithubRepositoryInfo -Account $Account -Context $Context -Name $Name

    if ($Browser) {
        return Start-Process $repository.html_url
    }

    # Replace existing repository
    if ($replace) {
        if ($PSCmdlet.ShouldProcess($repository.LocalPath, 'Do you want to replace the existing repository and any data in it.')) {
            Remove-Item -Path $repository.LocalPath -Recurse -Force -Confirm:$false
        }
    }

    # Clone via http or ssh
    if (!(Test-Path -Path $repository.LocalPath)) {
        $repository.LocalPath = New-Item -ItemType Directory -Path $repository.LocalPath

        if ($accountContext.useSSH) {
            git -C $repository.LocalPath clone $repository.ssh_url .
        }
        else {
            git -C $repository.LocalPath clone $repository.clone_url .
        }
    }
    
    $safeDirectoyPath = ($repository.LocalPath -replace '[\\]+', '/' )
    $included = (git config --global --get-all safe.directory | Where-Object { $_ -eq $safeDirectoyPath } | Measure-Object).Count -gt 0
    if (!$included) {
        $null = git config --global --add safe.directory $safeDirectoyPath
    }

    $null = git -C $repository.LocalPath config --local user.name $user.login 
    $null = git -C $repository.LocalPath config --local user.email $user.email
    $null = git -C $repository.LocalPath config --local commit.gpgsign $accountContext.commitSigning

    if (!$onlyDownload) {
        Open-InCodeEditor -Programm $CodeEditor -Path $repository.Localpath
    }

    return Get-Item $repository.LocalPath
}