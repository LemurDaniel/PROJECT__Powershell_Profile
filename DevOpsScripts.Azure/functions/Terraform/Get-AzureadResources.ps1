


<#

.SYNOPSIS
    Get resource-options for the given provider resource of the azurerm_provider.
    Only current set subscription is considered.
    Used by New-TerraformAzureImportStatement.ps1

.DESCRIPTION
    Get resource-options for the given provider resource of the azurerm_provider.
    Only current set subscription is considered.
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

    Get all resources for provider type 'azuread_application':

    PS> Get-AzureadResources -Azureadresource 'azuread_application' | Select-Object -Property slug, importId

.LINK
  
#>


function Get-AzureadResources {

    param (
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [System.String]
        $AzureadResource
    )

    switch ($AzureadResource) {

        'azuread_application' {
            return Get-AzADApplication
            | Select-Object -Property *, 
            @{
                Name       = "slug"; 
                Expression = { $_.DisplayName }
            },
            @{
                Name       = "importId"; 
                Expression = { $_.Id }
            }
        }

        # TODO 

        Default {  
            Throw "'$_' not Supported!"
        }
    }  

}