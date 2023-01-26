
function Get-QuickContexts {

    [CmdletBinding()]
    param ()
    return (Get-UtilsCache -Type Context -Identifier quick -AsHashtable) ?? [System.Collections.Hashtable]::new()
}