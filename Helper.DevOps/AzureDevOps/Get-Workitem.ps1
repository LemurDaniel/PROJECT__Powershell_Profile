function Get-WorkItem {

    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [System.String[]]
        $ids
    )

    Begin {
        $workItems = [System.Collections.ArrayList]::new()
    }
    Process {
        $Request = @{
            Method = 'GET'
            SCOPE  = 'PROJ'
            API    = '_apis/wit/workitems/?api-version=7.0'
            Query  = @{
                ids = ($ids | ForEach-Object { $_.trim() } ) -join ','
            }
        }

        $workItems.Add((Invoke-DevOpsRest @Request -return 'value.fields'))
    }
    End {
        return $workItems.GetEnumerator() | ForEach-Object { $_ }
    }   
}
