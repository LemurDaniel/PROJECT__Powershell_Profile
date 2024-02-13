<#
    .SYNOPSIS
    Get a list of all releases of a repository.

    .DESCRIPTION
    Get a list of all releases of a repository.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Get releases for the current repository:

    PS> GetGet-GithubReleases


    .EXAMPLE

     Get releases for another repository:

    PS> GetGet-GithubReleases <autocomplete_repo>


    .EXAMPLE

    Get releases for other accounts, contexts, etc:
    
    PS> GetGet-GithubReleases -Context <autocomplete_context> <autocomplete_repo>

    PS> GetGet-GithubReleases -Account <autocompleted_account> <autocomplete_repo>

    PS> GetGet-GithubReleases -Account <autocompleted_account> -Context <autocomplete_context> <autocomplete_repo>


    .LINK
        
#>

function Get-GithubReleases {

    param (
        # The name of the github account to use. Defaults to current Account.
        [Parameter(
            Position = 2,
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
            Position = 1
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
        [Alias('r')]
        $Repository,
        

        [Parameter()]
        [switch]
        $Refresh
    )

    $repositoryData = Get-GithubRepositoryInfo -Account $Account -Context $Context -Name $Repository

    $Identifier = "releases.$($repositoryData.Context).$($repositoryData.name)"
    $data = Get-GithubCache -Identifier $Identifier -Account $repositoryData.Account

    if ($null -EQ $data -OR $Refresh) {
        $Request = @{
            Method  = "GET"
            URL     = $repositoryData.release_url -replace '{/id}', ''
            Account = $repositoryData.Account
        }
        $data = (Invoke-GithubRest @Request) ?? @()
        $data = Set-GithubCache -Object $data -Identifier $Identifier -Account $repositoryData.Account
    }

    return $data
}