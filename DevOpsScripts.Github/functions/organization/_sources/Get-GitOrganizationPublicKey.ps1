<#
    .SYNOPSIS
    Get the public key for an organization.

    .DESCRIPTION
    Get the public key for an organization.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .LINK
        
#>

function Get-GitOrganizationPublicKey {

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


    $Identifier = "publickey"

    $data = Get-GitCache  -Identifier $Identifier @contextInfo

    if ($null -EQ $data) {
        $Request = @{
            Method  = "GET"
            API     = "/orgs/$($contextInfo.Context)/actions/secrets/public-key"
            Account = $contextInfo.Account
        }
        $data = Invoke-GitRest @Request
        $data = Set-GitCache -Object $data -Identifier $Identifier @contextInfo
    }

    return $data
}