
<#
    .SYNOPSIS
    Returns a list of all providers maintained by hasicorp.

    .DESCRIPTION
    Returns a list of all providers maintained by hasicorp.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .LINK
        
#>

function Get-TerraformProviders {

    [cmdletbinding()]
    param ()

    $providerData = Get-UtilsCache -Type 'terraform.provider' -Identifier 'all'

    if ($null -eq $providerData) {
        $apiUrl = "https://registry.terraform.io/v1/providers/hashicorp?offset={{offset}}"
        $offset = 0
        $providerData = @()

        do {
            $response = Invoke-RestMethod -Method Get -Uri $apiUrl.replace('{{offset}}', $offset)
            $offset  = $response.meta.next_offset
            $providerData += $response.providers
        } while ($null -ne $offset )

        $providerData = Set-UtilsCache -Object $providerData -Type 'terraform.provider' -Identifier 'all' -Alive 7200

    }

    return $providerData
}  
