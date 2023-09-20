
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
        $AutoLogin,

        [Parameter()]
        [switch]
        $UseDeviceAuthentication
    )

    $token = $null
    $expired = $false

    if ($Tool -EQ 'AzPowerShell') {

        if ($TenantId) {
            $token = Get-AzAccessToken -TenantId $TenantId -ErrorAction SilentlyContinue
        }
        else {
            $token = Get-AzAccessToken  -ErrorAction SilentlyContinue
        }
      

        $expired = $null -EQ $token -OR $token.ExpiresOn.UtcDateTime -LT [DateTime]::Now.ToUniversalTime()
        if(!$expired) {
            return $token
        }
        elseif(!$AutoLogin) {
            return $false
        }


        if($UseDeviceAuthentication) {
            Write-Host -ForegroundColor Yellow "https://microsoft.com/devicelogin"
        }
        if ($TenantId) {
            Connect-AzAccount -TenantId $TenantId -UseDeviceAuthentication:$UseDeviceAuthentication
            $token = Get-AzAccessToken -TenantId $TenantId
        }
        else {
            Connect-AzAccount -UseDeviceAuthentication:$UseDeviceAuthentication
            $token = Get-AzAccessToken
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
        if(!$expired) {
            return $token
        }
        elseif(!$AutoLogin) {
            return $false
        }

        $loginOptions = @()
        if($UseDeviceAuthentication) {
            $loginOptions += "--use-device-code"
        }   
        if($tenantId) {
            $loginOptions += "--tenant"
            $loginOptions += $TenantId
        }

        az login $loginOptions
        if ($TenantId) {
            $token = az account get-access-token --tenant $TenantId 2>$null | ConvertFrom-Json -Depth 4
        }
        else {
            $token = az account get-access-token 2>$null | ConvertFrom-Json -Depth 4
        }

    }


    return $token
}