<#
    .SYNOPSIS
    Gets all secerts on an organization.

    .DESCRIPTION
    Gets all secerts on an organization.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .LINK
        
#>

function Get-GitOrganizationSecret {

    param (
        # The name of the Git account to use. Defaults to current Account.
        [Parameter(
            Position = 1,
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
            Position = 0
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Context' })]
        [System.String]
        [Alias('c')]
        [Alias('context')]
        $Organization
    )

    $contextData = Get-GitContextInfo -Account $Account -Context $Organization
    $contextInfo = @{
        Account = $contextData.Account
        Context = $contextData.Context
    }

    $Request = @{
        Method  = "GET"
        API     = "/orgs/$($contextInfo.Context)/actions/secrets"
        Account = $contextInfo.Account
    }
    return Invoke-GitRest @Request
    | Select-Object -ExpandProperty secrets
}