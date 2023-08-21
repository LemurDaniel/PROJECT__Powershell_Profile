<#
    .SYNOPSIS
    Show the current Context as Commandline Ouput.

    .DESCRIPTION
    Show the current Context as Commandline Ouput.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Show the current Context as Commandline Ouput.


    .EXAMPLE

    Show the current Context as Commandline Ouput.

    PS> Show-DevOpsContext


    .LINK
        
#>
function Show-DevOpsContext {

    [CmdletBinding()]
    param ()

    $Organization = Get-DevOpsContext -Organization
    $Project = Get-DevOpsContext -Project
     
    Write-Host -ForegroundColor GREEN "`nCurrent Context:"
    Write-Host -ForegroundColor GREEN "     Organization: $Organization "
    Write-Host -ForegroundColor GREEN "     Project:      $Project"
    Write-Host
}