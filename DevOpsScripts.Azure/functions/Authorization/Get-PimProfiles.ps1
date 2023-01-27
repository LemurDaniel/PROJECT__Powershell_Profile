<#
    .SYNOPSIS
    All PIM-Profiles as a hastable.

    .DESCRIPTION
    All PIM-Profiles as a hastable.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Pim-Profiles as a hashtable.

    
    .LINK
        
#>
function Get-PimProfiles {

    [cmdletbinding()]
    param()

    return (Get-UtilsCache -Type PIM_Profiles -Identifier (Get-AzContext).Account.Id -AsHashTable) ?? [System.Collections.Hashtable]::new()

}