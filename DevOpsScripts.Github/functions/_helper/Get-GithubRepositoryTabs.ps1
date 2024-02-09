<#
    .SYNOPSIS
    Get github repository tabs links.

    .DESCRIPTION
    Get github repository tabs links.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .LINK
        
#>

function Get-GithubRepositoryTabs {

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