<#
    .SYNOPSIS
    Switches to a predefined Quick-Context.

    .DESCRIPTION
    Switches to a predefined Quick-Context.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Switch to a Quick-Context by name.

    PS> Switch-QuickContext <Context_name>


    .LINK
        
#>
function Switch-QuickContext {

    [Alias('swc')]
    [CmdletBinding()]
    param (
        # The name of the Context to switch to.
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

    $Organization = (Get-QuickContexts)[$ContextName].Organization
    $Project = (Get-QuickContexts)[$ContextName].Project
    $null = Set-DevOpsContext -Organization $Organization -Project $Project

    Show-DevOpsContext
}