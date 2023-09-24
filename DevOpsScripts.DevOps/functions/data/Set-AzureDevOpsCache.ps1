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
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true
        )]
        [PSCustomObject]
        $Object = @{},

        # The Type of the cache like Pipeline, Project, etc.
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $Type,

        # An identifier like name of the project, all, current, etc.
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $Identifier,

        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Organization,

        # The TTL of the cache in Minutes.
        [Parameter(Mandatory = $false)]
        [System.int32]
        $Alive = 720,

        # A Flag to never expire the cache.
        [Parameter(
            Mandatory = $false
        )]
        [switch]
        $Forever
    )

    BEGIN {
        $inputList = [System.Collections.ArrayList]::new()
    }

    PROCESS {
        $null = $inputList.Add($Object)
    }
    
    END {
        
        $Organization = [System.String]::IsNullOrEmpty($Organization) ? (Get-DevOpsContext -Organization) : $Organization
        $Cache = @{
            Object     = $inputList
            Type       = $Type
            identifier = "$Organization.$Identifier"
            Alive      = $Alive
            Forever    = $Forever
        }

        if ($inputList.Count -EQ 1) {
            $Cache.Object = $inputList[0]
        }

        return Set-UtilsCache @Cache
    }

}