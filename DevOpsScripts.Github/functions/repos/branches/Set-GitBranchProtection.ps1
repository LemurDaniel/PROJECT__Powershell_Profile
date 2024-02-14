<#
    .SYNOPSIS
    Sets branch protection rules for a branch.

    .DESCRIPTION
    Sets branch protection rules for a branch.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Adding/Updating branch protection rules for a branch:

    PS> Set-GitBranchProtection -Branch <autocompleted_branch> -AllowForcePushes -ConversationResolution

    .LINK
        
#>

function Set-GitBranchProtection {

    [CmdletBinding()]
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


        # The name of the target branch
        [Parameter(
            Mandatory = $true
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Branch' })]
        [System.String]
        $Branch,

        # Requires all conversations on code to be resolved before a pull request can be merged into a branch that matches this rule. Set to false to disable. Default: false.
        [Parameter()]
        [switch]
        $ConverstionResolution,
        # Permits force pushes to the protected branch by anyone with write access to the repository.
        [Parameter()]
        [switch]
        $AllowForcePushes,
        # Enforces a linear commit Git history, which prevents anyone from pushing merge commits to a branch. 
        [Parameter()]
        [switch]
        $LinearHistory,
        # Allows deletion of the protected branch by anyone with write access to the repository.
        [Parameter()]
        [switch]
        $AllowDeletions,
        # If set to true, the restrictions branch protection settings which limits who can push will also block pushes which create new branches, unless the push is initiated by a user, team, or app which has the ability to push.
        [Parameter()]
        [switch]
        $BlockCreation,
        # Whether to set the branch as read-only. If this is true, users will not be able to push to the branch. Default: false.
        [Parameter()]
        [switch]
        $LockBranch,
        # Whether users can pull changes from upstream when the branch is locked. Set to true to allow fork syncing.
        [Parameter()]
        [switch]
        $ForkSyncing
    )

    $repositoryData = Get-GitRepositoryInfo -Account $Account -Context $Context -Name $Repository

    $Request = @{
        METHOD  = "PUT"
        API     = "/repos/$($repositoryData.full_name)/branches/$Branch/protection"
        Account = $repositoryData.Account
        Body    = @{
        
            required_status_checks           = $null
            enforce_admins                   = $null
            required_pull_request_reviews    = $null
            restrictions                     = $null

            required_conversation_resolution = $ConverstionResolution -eq $true
            required_linear_history          = $LinearHistory -eq $true
            allow_deletions                  = $AllowDeletions -eq $true
            block_creations                  = $BlockCreation -eq $true
            lock_branch                      = $LockBranch -eq $true
            allow_fork_syncing               = $ForkSyncing -eq $true
            allow_force_pushes               = $AllowForcePushes -eq $true
        }
    }

    return Invoke-GitRest @Request
    
}