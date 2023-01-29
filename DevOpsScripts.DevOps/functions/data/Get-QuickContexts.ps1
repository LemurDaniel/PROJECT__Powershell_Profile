<#
    .SYNOPSIS
    Gets Hashtable of all Quick-Contexts.

    .DESCRIPTION
    Gets Hashtable of all Quick-Contexts.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Hashtable of all Quick-Contexts.


    .EXAMPLE

    Gets Hahstable of all Quick-Contexts.

    PS> Get-QuickContexts
    
    .LINK
        
#>
function Get-QuickContexts {

    [CmdletBinding()]
    param ()
    return (Get-UtilsCache -Type Context -Identifier quick -AsHashtable) ?? [System.Collections.Hashtable]::new()
}