<#
    .SYNOPSIS
    Gets Workitems in the current project by id.

    .DESCRIPTION
    Gets Workitems in the current project by id.

    .INPUTS
    You can Pipe ids into the command via other commands.

    .OUTPUTS
    System.PSCustomObject[] List of workitems from DevOps-API.

    .EXAMPLE

    Get Workitmes by ids:

    PS> 1,2,3 | Get-Workitems

    .EXAMPLE

    Get Workitmes by previous search-query

    PS> Select-Workitems -Query 'query' -return 'workitems.id' | Get-Workitems


    .LINK
        
#>

function Get-WorkItems {

    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [System.String[]]
        $Ids
    )

    Begin {
        $IdList = [System.Collections.ArrayList]::new()
    }
    Process {
        $null = $IdList.Add(($Ids | ForEach-Object { $_ }))
    }
    End {

        $Request = @{
            Method = 'GET'
            SCOPE  = 'PROJ'
            API    = '_apis/wit/workitems/?api-version=7.0'
            Query  = @{
                ids = $IdList -join ','
            }
        }

        return Invoke-DevOpsRest @Request -return 'value.fields'
    }   
}
