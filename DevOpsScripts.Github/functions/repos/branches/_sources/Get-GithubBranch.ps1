<#
    .SYNOPSIS
    Retrieves a list of all branches for that repository.

    .DESCRIPTION
    Retrieves a list of all branches for that repository.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Get brances for the current repository:

    PS> Get-GithubBranch


    .EXAMPLE

    Get brances for another repository:

    PS> Get-GithubBranch <autocomplete_repo>


    .EXAMPLE

    Get brances for other accounts, contexts, etc:
    
    PS> Get-GithubBranch -Context <autocomplete_context> <autocomplete_repo>

    PS> Get-GithubBranch -Account <autocompleted_account> <autocomplete_repo>

    PS> Get-GithubBranch -Account <autocompleted_account> -Context <autocomplete_context> <autocomplete_repo>
    


    .LINK
        
#>

function Get-GithubBranch {

    [CmdletBinding()]
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
        $Repository
    )

    $repositoryData = Get-GithubRepositoryInfo -Account $Account -Context $Context -Name $Repository

    $Identifier = "branches.$($repositoryData.Context).$($repositoryData.name)"
    $data = Get-GithubCache -Identifier $Identifier -Account $repositoryData.Account

    if ($null -EQ $data -OR $Refresh) {
        $Request = @{
            Method  = "GET"
            API     = "/repos/$($repositoryData.full_name)/branches"
            Account = $repositoryData.Account
        }
        $data = Invoke-GithubRest @Request
        $data = Set-GithubCache -Object $data -Identifier $Identifier -Account $repositoryData.Account
    }

    return $data
}