<#
    .SYNOPSIS
    Get Git repository tabs links.

    .DESCRIPTION
    Get Git repository tabs links.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .LINK
        
#>

function Get-GitRepositoryTabs {

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Tabname
    )

    $content = Get-Content -Path "$PSScriptRoot/../.resources/repository.tabs.json" | ConvertFrom-Json -AsHashtable

    if (![System.String]::IsNullOrEmpty($Tabname)) {
        return $content[$Tabname]
    }

    return $content
}