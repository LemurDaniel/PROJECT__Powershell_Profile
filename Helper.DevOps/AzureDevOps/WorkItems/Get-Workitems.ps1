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
