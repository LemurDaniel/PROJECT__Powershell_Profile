

<#

.SYNOPSIS
    TODO

.DESCRIPTION
    TODO


.EXAMPLE
    TODO

    Mostly still testing

    Select-AzContext ...
    tf-azimport ... ... ...

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

    return Get-Content -Path "$PSScriptRoot" | ConvertFrom-Json -Depth 99
    | Where-Object {
        $_.slug -EQ $providerResource.replace('azurerm_', '') -OR $_.slug -EQ $providerResource
    }
}
