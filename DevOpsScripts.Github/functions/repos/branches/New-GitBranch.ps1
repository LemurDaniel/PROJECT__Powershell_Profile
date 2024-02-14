<#
    .SYNOPSIS
    Create a new Git branch from an issue.

    .DESCRIPTION
    Create a new Git branch from an issue.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Create a Branch name from an Issue:

    PS> New-GitBranch --FromIssue <autocompleted_issue_title>


    .LINK
        
#>

function New-GitBranch {

    [CmdletBinding()]
    [Alias('git-branch')]
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
        [Alias('r')]
        $Repository,

        # The base branch from which to create another. Defaults to default branch.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Base,

        # Paremter to create a pull request from an issue, identified by issue title, with interactive argument completer.
        [Parameter(
            ParameterSetName = "FromIssueTitle"
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args -alias 'IssueOpen' })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'IssueOpen' })]
        [System.String]
        $FromIssue
    )

    $repositoryData = Get-GitRepositoryInfo -Account $Account -Context $Context -Name $Repository

    if ([System.String]::IsNullOrEmpty($base)) {
        $Base = $repositoryData.default_branch
    }

    if ($PSBoundParameters.ContainsKey("FromIssue")) {
        $Issue = Get-GitIssues -Account $Account -Context $Context -Repository $Repository
        | Where-Object -Property title -EQ $FromIssue

        $target = [System.String]::Format("{0}-{1}", $Issue.number, $Issue.title).toLower() `
            -replace '[^a-z0-9_-]', '_' `
            -replace '-+', '-' `
            -replace '_+', '_' `
            -replace '_-', '_' `
            -replace '-_', '_' `
            -replace '_$|-$', ''

        git -C $repositoryData.LocalPath fetch origin
        git -C $repositoryData.LocalPath checkout $Base
        git -C $repositoryData.LocalPath checkout -B $target
        git -C $repositoryData.LocalPath push origin $target

    }
    
    else {
        throw [System.NotSupportedException]::new("Please provde a valid issue.")
    }
  
}