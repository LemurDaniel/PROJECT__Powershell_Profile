

<#

.SYNOPSIS
    TODO

.DESCRIPTION
    TODO


.EXAMPLE
    TODO

.LINK
  

#>



function Get-AzureResourceTypes {

    param ()

    $resourceTypes = Get-UtilsCache -Identifier "azure.resourceTypes.list"

    if ($null -EQ $resourceTypes) {

        $resourceTypes = @()
        $resourceProviders = Get-AzResourceProvider 
        foreach ($provider in $resourceProviders) {
            foreach ($type in $provider.ResourceTypes) {
                $resourceTypes += "$($provider.ProviderNamespace)/$($type.ResourceTypeName)"
            }
        }

        $resourceTypes = $resourceTypes | Set-UtilsCache -Identifier "azure.resourceTypes.list" -Alive 60
    }

    return $resourceTypes
}
