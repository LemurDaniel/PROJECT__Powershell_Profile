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

    PS> GetGet-GitReleases


    .EXAMPLE

     Get releases for another repository:

    PS> GetGet-GitReleases <autocomplete_repo>


    .EXAMPLE

    Get releases for other accounts, contexts, etc:
    
    PS> GetGet-GitReleases -Context <autocomplete_context> <autocomplete_repo>

    PS> GetGet-GitReleases -Account <autocompleted_account> <autocomplete_repo>

    PS> GetGet-GitReleases -Account <autocompleted_account> -Context <autocomplete_context> <autocomplete_repo>


    .LINK
        
#>

function Get-GitReleases {

    param (
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
        $Repository,
        

        [Parameter()]
        [switch]
        $Refresh
    )

    $repositoryData = Get-GitRepositoryInfo -Account $Account -Context $Context -Name $Repository

    $Identifier = "releases.$($repositoryData.Context).$($repositoryData.name)"
    $data = Get-GitCache -Identifier $Identifier -Account $repositoryData.Account

    if ($null -EQ $data -OR $Refresh) {
        $Request = @{
            Method  = "GET"
            URL     = $repositoryData.release_url -replace '{/id}', ''
            Account = $repositoryData.Account
        }
        $data = (Invoke-GitRest @Request) ?? @()
        $data = Set-GitCache -Object $data -Identifier $Identifier -Account $repositoryData.Account
    }

    return $data
}