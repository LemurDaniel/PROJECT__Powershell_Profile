<#
    .SYNOPSIS
    Get the Cache-Content of an Azure DevOps Cache.

    .DESCRIPTION
    Get the Cache-Content of an Azure DevOps Cache to reduce API-Calls

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    PSObject of the Cache-Content.


    .EXAMPLE

    Get the Cache for Type 'Pipeline' in the Project 'Teamsbuilder'

    PS> Get-AzureDevOpsCache -Type 'Pipeline' -Identifier 'Teamsbuilder'

    
    .LINK
        
#>
function Get-AzureDevOpsCache {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Type,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Identifier,

        [Parameter(Mandatory = $false)]
        [System.String]
        $Organization
    )

    $Organization = [System.String]::IsNullOrEmpty($Organization) ? (Get-DevOpsContext -Organization) : $Organization
    return Get-UtilsCache -Type $Type -Identifier "$Organization.$Identifier"

}