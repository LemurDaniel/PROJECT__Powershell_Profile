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

    PS> Get-GithubRepositoryInfo

    .EXAMPLE

    Get Info about a Repository in the current Context:

    PS> Get-GithubRepositoryInfo <autocomplete_repo>

    .EXAMPLE

    Get Info about a Repository in the another Context:

    PS> Get-GithubRepositoryInfo -Context <autocomplete_context> <autocomplete_repo>

    .LINK
        
#>

function Get-GithubRepositoryInfo {

    param(
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
            Position = 1
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Repository' })]
        [System.String]
        [Alias('r')]
        [Alias('Name')]
        $Repository,
        

        [Parameter()]
        [switch]
        $Refresh
    )

    if ([System.String]::IsNullOrEmpty($Repository) -and [System.String]::IsNullOrEmpty($Context)) {

        $currentPath = Get-Location
        if (!(Test-IsRepository)) {
            throw "'$currentPath' is not a valid repositorypath."
        }
        $repoPath = git -C $currentPath rev-parse --show-toplevel
        $Repository = $repoPath.split('/')[-1]
        $Context = $repoPath.split('/')[-2]
        $Account = $repoPath.split('/')[-3]
    }

    $repositoryData = Get-GithubContextInfo -Account $Account -Context $Context -Refresh:$Refresh 
    | Select-Object -ExpandProperty repositories 
    | Where-Object -Property Name -EQ -Value $Repository

    if ($null -eq $repositoryData) {
        throw "No Repository found for '$RepositoryName' in Context '$Context' for '$Account'"
    }

    return $repositoryData

}
