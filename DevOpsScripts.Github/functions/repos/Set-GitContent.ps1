<#
    .SYNOPSIS
    Creates or update content in a repository.

    .DESCRIPTION
    Creates or update content in a repository.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .LINK
        
#>

function Set-GitContent {

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
        [Alias('Name')]
        $Repository,


        # The name of the target branch. Defaults to default branch.
        [Parameter(
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        # [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Branch' })]
        [System.String]
        $Branch,

        # The path to the file inside the repository.
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $Path,

        # The content to set on the path.
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $Content,

        # The commit message for updating content.
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $Message
    )

    $repositoryData = Get-GitRepositoryInfo -Account $Account -Context $Context -Name $Repository

    $contentBytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
    $Request = @{
        Method  = 'PUT'
        API     = "/repos/$($repositoryData.full_name)/contents/$path"
        Account = $repositoryData.Account
        Body    = @{
            message = $message
            content = [System.Convert]::ToBase64String($contentBytes)
            branch  = [System.String]::IsNullOrEmpty($branch) ? $repositoryData.default_branch : $Branch
        }
    }

    return Invoke-GitRest @Request  -Verbose
}