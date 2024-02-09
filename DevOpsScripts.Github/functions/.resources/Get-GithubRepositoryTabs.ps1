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

    $jsonConfigurationPath = "C:\Users\Daniel\git\repos\GITHUB\LemurDaniel\LemurDaniel\PROJECT__Powershell_Profile\DevOpsScripts.Github\functions\.resources\repository.tabs.json"
    $content = Get-Content -Path $jsonConfigurationPath | ConvertFrom-Json -AsHashtable

    if (![System.String]::IsNullOrEmpty($Tabname)) {
        return $content[$Tabname]
    }
    return $content

}