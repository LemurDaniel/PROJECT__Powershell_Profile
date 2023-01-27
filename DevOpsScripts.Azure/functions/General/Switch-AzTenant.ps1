
<#
    .SYNOPSIS
    Switches to a Tenant accessible by the connected user.

    .DESCRIPTION
    Switches to a Tenant accessible by the connected user.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .LINK
        
#>
function Switch-AzTenant {

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [ValidateScript(
            { 
                $_ -in (Get-AzTenant).Name
            },
            ErrorMessage = 'Please specify an correct Name.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-AzTenant).Name
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Tenant
    )


    $tenantId = ((Get-AzTenant).Name | Where-Object -Property Name -EQ -Value $Tenant).id
    if (!$NoDisconnect) {
        Disconnect-AzAccount
    }

    $null = Connect-AzAccount -Tenant $tenantId
    $null = az login --tenant $tenantId
    
}