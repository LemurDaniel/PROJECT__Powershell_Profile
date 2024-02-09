<#
    .SYNOPSIS
    Gets the environments for a github repository.

    .DESCRIPTION
    Gets the environments for a github repository.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Get environments for the current repository:

    PS> Get-GithubEnvironments


    .EXAMPLE

     Get environments for another repository:

    PS> Get-GithubEnvironments <autocomplete_repo>


    .EXAMPLE

    Get environments for other accounts, contexts, etc:
    
    PS> Get-GithubEnvironments -Context <autocomplete_context> <autocomplete_repo>

    PS> Get-GithubEnvironments -Account <autocompleted_account> <autocomplete_repo>

    PS> Get-GithubEnvironments -Account <autocompleted_account> -Context <autocomplete_context> <autocomplete_repo>
    

    .LINK
        
#>

function Get-GithubEnvironments {

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
            Position = 1
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

    $Identifier = "environments.$($repositoryData.Context).$($repositoryData.name)"
    $data = Get-GithubCache -Identifier $Identifier -Account $repositoryData.Account

    if ($null -EQ $data -OR $Refresh) {
        $Request = @{
            Method  = "GET"
            API     = "/repos/$($repositoryData.full_name)/environments"
            Account = $repositoryData.Account
        }
        $data = Invoke-GithubRest @Request
        $data = Set-GithubCache -Object $data.environments -Identifier $Identifier -Account $repositoryData.Account
    }

    return $data
}