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

    PS> Get-GitRepositoryInfo

    .EXAMPLE

    Get Info about a Repository in the current Context:

    PS> Get-GitRepositoryInfo <autocomplete_repo>

    .EXAMPLE

    Get Info about a Repository in the another Context:

    PS> Get-GitRepositoryInfo -Context <autocomplete_context> <autocomplete_repo>

    .LINK
        
#>

function Get-GitRepositoryInfo {

    param(
        # The name of the Git account to use. Defaults to current Account.
        [Parameter(
            Position = 2,
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
            Position = 1
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
        [Alias('Name')]
        $Repository,
        

        [Parameter()]
        [switch]
        $Refresh
    )

    $repositoryIdentifier = @{
        Account    = $Account
        Context    = $Context
        Repository = $Repository
    }

    if ([System.String]::IsNullOrEmpty($Repository) -and [System.String]::IsNullOrEmpty($Context)) {

        $currentPath = Get-Location
        if (!(Test-IsRepository)) {
            throw "'$currentPath' is not a valid repositorypath."
        }
        $repoPath = git -C $currentPath rev-parse --show-toplevel
        $repositoryIdentifier.Account = $repoPath.split('/')[-3]
        $repositoryIdentifier.Context = $repoPath.split('/')[-2]
        $repositoryIdentifier.Repository = $repoPath.split('/')[-1]
    }

    $repositoryData = Get-GitContextInfo -Account $repositoryIdentifier.Account -Context $repositoryIdentifier.Context -Refresh:$Refresh 
    | Select-Object -ExpandProperty repositories 
    | Where-Object -Property Name -EQ -Value $repositoryIdentifier.Repository
    
    if ($null -eq $repositoryData) {
        throw "No Repository found for '$($repositoryIdentifier.RepositoryName)' in Context '$($repositoryIdentifier.Context)' for '$($repositoryIdentifier.Account)'"
    }

    return $repositoryData

}
