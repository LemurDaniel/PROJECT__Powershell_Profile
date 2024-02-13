<#
    .SYNOPSIS
    Adds or Updates a Secret in a Github-Organization via API.

    .DESCRIPTION
    Adds or Updates a Secret in a Github-Organization via API.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .LINK
        
#>

function Set-GithubOrganizationSecret {

    [CmdletBinding(
        DefaultParameterSetName = "Single"
    )]
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
        [Alias('context')]
        $Organization,


        
        # The name of the secret.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "Single"
        )]
        [System.String]
        $Name,

        # The value of the secret.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "Single"
        )]
        [System.String]
        $Value,

        # The hashtable of secret names and values to add to the repository.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "Hashtable"
        )]
        [System.Collections.Hashtable]
        $Secrets,

        # The visibility of the variable accross the organization.
        [parameter()]
        [validateSet('all', 'selected', 'private')]
        [System.String]
        $Visibility = 'all'
    )

    if (!(npm list sodium-native -g -json | Select-String 'sodium-native')) {
        npm install sodium-native -g
    }


    $contextData = Get-GithubContextInfo -Account $Account -Context $Organization
    $contextInfo = @{
        Account = $contextData.Account
        Context = $contextData.Context
    }

    if (!$PSBoundParameters.ContainsKey("Secrets")) {
        $Secrets = [System.Collections.Hashtable]::new()
        $null = $Secrets.add($Name, $Value)
    }

    $publicKey = Get-GithubOrganizationPublicKey @contextInfo

    $Secrets.GetEnumerator() 
    | ForEach-Object {

        Write-Host -ForegroundColor GREEN "Setting Secret '$($_.Key)'"
        $encryptedSecret = node "$PSScriptRoot/../.resources/encrypt.js" $_.Value $publicKey.key

        $Request = @{
            METHOD  = "PUT"
            API     = "/orgs/$($contextInfo.Context)/actions/secrets/$($_.Key)"
            Account = $contextInfo.Account
            Body    = @{
                encrypted_value = $encryptedSecret
                key_id          = $publicKey.key_id
                visibility      = $Visibility
            }
        }

        $null = Invoke-GithubRest @Request
    }
    
}