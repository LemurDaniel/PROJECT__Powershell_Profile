<#
    .SYNOPSIS
    Set the Cache-Content of an Azure DevOps Cache.

    .DESCRIPTION
    Set the Cache-Content of an Azure DevOps Cache to reduce API-Calls

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    PSObject of the Cache-Content.


    .EXAMPLE

    Set the Cache for Type 'Pipeline' in the Project 'Teamsbuilder' to a default of 60 minutes. 

    PS> Set-AzureDevOpsCache -Object $Pipelines -Type 'Pipeline' -Identifier 'Teamsbuilder'

    
    .LINK
        
#>
function Set-AzureDevOpsCache {

    [CmdletBinding()]
    param (
        # The Powershell Object to be cached.
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $Object,

        # The Type of the cache like Pipeline, Project, etc.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Type,

        # An identifier like name of the project, all, current, etc.
        [Parameter(Mandatory = $true)]
        [System.String]
        $Identifier,

        [Parameter(Mandatory = $false)]
        [System.String]
        $Organization,

        # The TTL of the cache in Minutes.
        [Parameter(Mandatory = $false)]
        [System.int32]
        $Alive = 60,

        # A Flag to never expire the cache.
        [Parameter(Mandatory = $false)]
        [switch]
        $Forever
    )

    $Organization = [System.String]::IsNullOrEmpty($Organization) ? (Get-DevOpsContext -Organization) : $Organization
    return Set-UtilsCache -Object $Object -Type $Type -Identifier "$Organization.$Identifier" -Alive $Alive -Forever:$Forever

}