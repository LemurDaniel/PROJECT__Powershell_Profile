<#
    .SYNOPSIS
    Downloads and opens a Git-Repository by current Context or specified.

    .DESCRIPTION
    Downloads and opens a Git-Repository by current Context or specified.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Path to the Repository

    .EXAMPLE

    Open a repository in the current Context:

    PS> Open-GitRepository <autocomplete_repo>

    .EXAMPLE

    Open a repository in the current Context:

    PS> Open-GitRepository <autocomplete_repo> -CodeEditor 'Visual Studio'

    .EXAMPLE

    Open a repository in another Context:

    PS> Open-GitRepository -Context <autocomplete_context> <autocomplete_repo>

    .EXAMPLE

    Open a repository in another Account and another Context:

    PS> Open-GitRepository -Account <autocompleted_account> -Context <autocomplete_context> <autocomplete_repo>

    .LINK
        
#>

function Open-GitRepository {

    [Alias('git-repo')]
    [cmdletbinding(
        SupportsShouldProcess,
        ConfirmImpact = 'high'
    )]
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

        # The Name of the Code Editor to use. Default to default.
        [Parameter(
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'CodeEditor' })]
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

    $user = Get-GitUser -Account $Account
    $accountContext = Get-GitAccountContext -Account $Account
    $repositoryData = Get-GitRepositoryInfo -Account $Account -Context $Context -Name $Repository

    if ($Browser) {
        return Start-Process $repositoryData.html_url
    }

    
    # Replace existing repository
    if ($replace) {
        if ($PSCmdlet.ShouldProcess($repositoryData.LocalPath, 'Do you want to replace the existing repository and any data in it.')) {
            Remove-Item -Path $repositoryData.LocalPath -Recurse -Force -Confirm:$false
        }
    }

    # Clone via http or ssh
    if (!(Test-Path -Path $repositoryData.LocalPath)) {
        $repositoryData.LocalPath = New-Item -ItemType Directory -Path $repositoryData.LocalPath

        if ($accountContext.useSSH) {
            git -C $repositoryData.LocalPath clone $repositoryData.ssh_url .
        }
        else {
            git -C $repositoryData.LocalPath clone $repositoryData.clone_url .
        }
    }
    
    $safeDirectoyPath = ($repositoryData.LocalPath -replace '[\\]+', '/' )
    $included = (git config --global --get-all safe.directory | Where-Object { $_ -eq $safeDirectoyPath } | Measure-Object).Count -gt 0
    if (!$included) {
        $null = git config --global --add safe.directory $safeDirectoyPath
    }

    $null = git -C $repositoryData.LocalPath config --local user.name $user.login 
    $null = git -C $repositoryData.LocalPath config --local user.email $user.email
    $null = git -C $repositoryData.LocalPath config --local commit.gpgsign $accountContext.commitSigning

    if (!$onlyDownload) {
        Open-InCodeEditor -Programm $CodeEditor -Path $repositoryData.Localpath
    }

    return Get-Item $repositoryData.LocalPath
}