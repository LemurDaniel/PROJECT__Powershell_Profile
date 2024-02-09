<#
    .SYNOPSIS
    Gets all secerts on a repository.

    .DESCRIPTION
    Gets all secerts on a repository.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Get all variables on the repository for the current path:

    PS> Get-GithubRepositorySecret 

    .EXAMPLE

    Get all variables of an environment on the repository for the current path:

    PS> Get-GithubRepositorySecret -Environment dev

    .LINK
        
#>

function Get-GithubRepositorySecret {

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
        $Repository,


        # The Environment where to get the secret from.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Environment
    )

    $repositoryData = Get-GithubRepositoryInfo -Account $Account -Context $Context -Name $Repository

    $remoteUrl = "/repos/$($repositoryData.full_name)/actions/secrets"
    if (![System.String]::IsNullOrEmpty($Environment)) {
        $remoteUrl = "/repositories/$($repositoryData.id)/environments/$Environment/secrets"
    }

    return Invoke-GithubRest -API $remoteUrl -Account $Account
    | Select-Object -ExpandProperty secrets

}