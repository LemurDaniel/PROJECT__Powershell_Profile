<#
    .SYNOPSIS
    Gets all variables on a repository.

    .DESCRIPTION
    Gets all variables on a repository.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Get all variables on the repository for the current path:

    PS> Get-GitVariable 

    .EXAMPLE

    Get all variables of an environment on the repository for the current path:

    PS> Get-GitVariable -Environment dev

    .LINK
        
#>

function Get-GitVariable {

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

        
        # The Environment where to get the variable from
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Environment
    )

    $repositoryData = Get-GitRepositoryInfo -Account $Account -Context $Context -Name $Repository

    $remoteUrl = "/repos/$($repositoryData.full_name)/actions/variables"
    if (![System.String]::IsNullOrEmpty($Environment)) {
        $remoteUrl = "/repositories/$($repositoryData.id)/environments/$Environment/variables"
    }

    return Invoke-GitRest -API $remoteUrl -Account $Account
    | Select-Object -ExpandProperty variables

}