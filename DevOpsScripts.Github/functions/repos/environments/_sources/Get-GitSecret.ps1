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

    PS> Get-GitSecret 

    .EXAMPLE

    Get all variables of an environment on the repository for the current path:

    PS> Get-GitSecret -Environment dev

    .LINK
        
#>

function Get-GitSecret {

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
            Position = 1
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Repository' })]
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

    $repositoryData = Get-GitRepositoryInfo -Account $Account -Context $Context -Name $Repository

    $remoteUrl = "/repos/$($repositoryData.full_name)/actions/secrets"
    if (![System.String]::IsNullOrEmpty($Environment)) {
        $remoteUrl = "/repositories/$($repositoryData.id)/environments/$Environment/secrets"
    }

    return Invoke-GitRest -API $remoteUrl -Account $Account
    | Select-Object -ExpandProperty secrets

}