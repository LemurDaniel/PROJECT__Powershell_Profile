
<#
    .SYNOPSIS
    Test if user is logged in to azure and still valid.

    .DESCRIPTION
    Test if user is logged in to azure and still valid.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Boolean if logged in.

    .EXAMPLE

    Test if user is logged in via Azure Cli:

    PS> Test-AzLogin AzCLI

    .EXAMPLE

    Automatically Connect-AzAccount, when not logged in:

    PS> Test-AzLogin AzPowerShell -AutoLogin

    .EXAMPLE

    Automatically Connect-AzAccount to a ceratin tennant, when not logged in:

    PS> Test-AzLogin AzPowerShell -TenantId <tenant_id> -AutoLogin

    .LINK
        
#>
function Test-AzLogin {

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [System.String]
        [ValidateSet(
            'AzCLI',
            'AzPowerShell'
        )]
        $Tool,

        [Parameter(
            Mandatory = $false,
            Position = 1
        )]
        [System.String]
        $TenantId,

        [Parameter()]
        [switch]
        $AutoLogin
    )

    $token = $null
    $expired = $false

    if ($Tool -EQ 'AzPowerShell') {
        try {
            if ($TenantId) {
                $token = Get-AzAccessToken -TenantId $TenantId
            }
            else {
                $token = Get-AzAccessToken
            }
        }
        catch {}

        $expired = $null -EQ $token -OR $token.ExpiresOn.UtcDateTime -LT [DateTime]::Now.ToUniversalTime()
        if (!$expired -AND $AutoLogin) {
            if ($TenantId) {
                Connect-AzAccount -TenantId $TenantId
                $token = Get-AzAccessToken -TenantId $TenantId
            }
            else {
                Connect-AzAccount
                $token = Get-AzAccessToken
            }
        }
    }

    if ($Tool -EQ 'AzCLI') {
        if ($TenantId) {
            $token = az account get-access-token --tenant $TenantId 2>$null | ConvertFrom-Json -Depth 4 -ErrorAction SilentlyContinue
        }
        else {
            $token = az account get-access-token 2>$null | ConvertFrom-Json -Depth 4 -ErrorAction SilentlyContinue
        }

        $expired = $null -EQ $token -OR [DateTime]::parse($token.ExpiresOn) -LT [DateTime]::Now.ToUniversalTime()
        if (!$expired -AND $AutoLogin) {
            if ($TenantId) {
                az login --tenant $TenantId
                $token = az account get-access-token --tenant $TenantId 2>$null | ConvertFrom-Json -Depth 4
            }
            else {
                az login
                $token = az account get-access-token 2>$null | ConvertFrom-Json -Depth 4
            }
        }
    }


    return $expired ? $false : $token
}