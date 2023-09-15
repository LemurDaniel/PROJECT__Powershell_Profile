<#

.SYNOPSIS
    Get resource-options for the given provider resource.
    For azure resources only current set subscription is considered.
    Used by New-TerraformAzureImportStatement.ps1

.DESCRIPTION
    Get resource-options for the given provider resource.
    For azure resources only current set subscription is considered.
    Used by New-TerraformAzureImportStatement.ps1

.OUTPUTS
    A list of resource options of
    @{
        slug      = ""
        import_id = ""
        .
        .
        .
        other properties depending on type
    }

.EXAMPLE

    Get all resources for provider type 'azurerm_resource_group':

    PS> Get-ProviderResources -ProviderResource 'azurerm_resource_group'

.LINK
  
#>

function Get-ProviderResources {

    param (
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [System.String]
        $ProviderResource
    )

    $ProviderResource = $ProviderResource -split "\." | Select-Object -Last 2 | Select-Object -First 1

    switch ($ProviderResource) {

        { $ProviderResource -like "azurerm_*" } { 
            return Get-AzurermResources -AzurermResource $ProviderResource
        }

        { $ProviderResource -like "azuread_*" } { 
            return Get-AzureadResources -AzureadResource $ProviderResource
        }

        Default {
            throw "'$ProviderResource' not supported!"
        }
    }
    
}