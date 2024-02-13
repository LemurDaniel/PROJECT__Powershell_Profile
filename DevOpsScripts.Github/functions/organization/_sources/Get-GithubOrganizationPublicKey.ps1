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

function Get-GithubOrganizationPublicKey {

    param (
        # The name of the github account to use. Defaults to current Account.
        [Parameter(
            Position = 1,
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
            Position = 0
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Context' })]
        [System.String]
        [Alias('c')]
        [Alias('context')]
        $Organization
    )

    $contextData = Get-GithubContextInfo -Account $Account -Context $Organization
    $contextInfo = @{
        Account = $contextData.Account
        Context = $contextData.Context
    }


    $Identifier = "publickey"

    $data = Get-GithubCache  -Identifier $Identifier @contextInfo

    if ($null -EQ $data) {
        $Request = @{
            Method  = "GET"
            API     = "/orgs/$($contextInfo.Context)/actions/secrets/public-key"
            Account = $contextInfo.Account
        }
        $data = Invoke-GithubRest @Request
        $data = Set-GithubCache -Object $data -Identifier $Identifier @contextInfo
    }

    return $data
}