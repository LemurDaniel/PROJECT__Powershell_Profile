function Get-PimProfiles {

    [cmdletbinding()]
    param()

    return (Get-UtilsCache -Type PIM_Profiles -Identifier (Get-AzContext).Account.Id -AsHashTable) ?? [System.Collections.Hashtable]::new()

}