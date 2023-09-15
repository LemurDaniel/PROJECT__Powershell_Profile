<#

.SYNOPSIS
    Get information about a azurerm provider resource.
    Used by New-TerraformAzureImportStatement.ps1

.DESCRIPTION
    Get information about a azurerm provider resource.
    Used by New-TerraformAzureImportStatement.ps1

.LINK
  
#>

function Get-TerraformAzuremMapping {

    param (
        # Parameter help description
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $providerResource
    )

    return Get-Content -Path "$PSScriptRoot/azurerm.resources.json" | ConvertFrom-Json -Depth 99
    | Where-Object {
        $_.slug -EQ $providerResource.replace('azurerm_', '') -OR $_.slug -EQ $providerResource
    }
}
