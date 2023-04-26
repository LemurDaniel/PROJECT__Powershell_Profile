
<#
    .SYNOPSIS
    Returns a list of all providers maintained by hasicorp.  For all verified terraform providers.

    .DESCRIPTION
    Returns a list of all providers maintained by hasicorp.  For all verified terraform providers.

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

        # Max Limit is 100
        $apiUrl = 'https://registry.terraform.io/v1/providers?offset={{offset}}&limit=100&verified=true'
        $previousOffset = 0
        $nextOffset = 0
        $providerData = @{}

        do {

            $response = Invoke-RestMethod -Method Get -Uri $apiUrl.replace('{{offset}}', $nextOffset)
            $previousOffset = $nextOffset
            $nextOffset = $response.meta.next_offset

            $response.providers | ForEach-Object { 
                $_ | Add-Member NoteProperty identifier "$($_.namespace)/$($_.name)"
                $providerData[$_.name] = $_ 
            }

        } while ($null -ne $nextOffset -AND $previousOffset -ne $nextOffset)

        $providerData = Set-UtilsCache -Object $providerData.values -Type 'terraform.provider' -Identifier 'all' -Alive 7200

    }

    return $providerData
}  
