<#
    .SYNOPSIS
    Remove a previous specified Quick-Context.

    .DESCRIPTION
    Remove a previous specified Quick-Context.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Hashtable of all avaialbe Quick-Contexts.


    .EXAMPLE

    Remove a Quick-Context:

    PS> Remove-QuickContext '<Quick_Context_Name>'
    
    .LINK
        
#>
function Remove-QuickContext {

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [ValidateScript(
            { 
                $_ -in (Get-QuickContexts).Keys
            },
            ErrorMessage = 'Please specify the correct Context.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-QuickContexts).Keys
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $ContextName
    )

    $contexts = (Get-QuickContexts)
    $contexts.Remove($ContextName)
    return Set-UtilsCache -Object $contexts -Type Context -Identifier quick
}