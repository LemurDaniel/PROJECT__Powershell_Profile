function Invoke-AzureRest {

    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $METHOD,

        [Parameter()]
        [System.String]
        $SCOPE,

        [Parameter()]
        [System.String]
        $API,

        [Parameter()]
        [System.Collections.Hashtable]
        $Query,

        [Parameter()]
        [PSCustomObject]
        $Body,

        [Alias('return')]
        [Parameter()]
        [System.String]
        $Property,

        [Parameter()]
        [switch]
        $AsArray,

        [parameter()]
        [string]
        $contentType
    )

    $APIEndpoint = ($API -split '\?')[0]
    
    # Build a hashtable of providedy Query params and Query params in provied api-url.
    $Query = $null -ne $Query ? $Query : [System.Collections.Hashtable]::new()
    $null = ($API -split '\?')[1] -split '&' | ForEach-Object { $Query.Add($_.split('=')[0], $_.split('=')[1]) }
    $QueryString = ($Query.GetEnumerator() | `
            Sort-Object -Descending { $_.Name -ne 'api-version' } | `
            ForEach-Object { "$($_.Name)=$($_.Value)" }) -join '&'


    if (!$Query['api-version']) {
        throw 'Please specify an api-version to use.'
    }


    $toplevelScope = $scope.contains('managementGroups') ? 'providers/Microsoft.Management' : 'providers/Microsoft.Subscriptions'
    $TargetURL = "https://management.azure.com/$toplevelScope/$scope/$APIEndpoint`?$QueryString"

    $Request = @{
        Method  = $METHOD
        Uri     = $TargetURL
        PayLoad = $body | ConvertTo-Json -Depth 8 -Compress -AsArray:$AsArray
    }

    Write-Verbose ($Request | ConvertTo-Json -Depth 8)
    $response = Invoke-AzRestMethod @Request


    if ($response.StatusCode -lt 200 -OR $response.StatusCode  -gt 201) {
        throw "$($response.StatusCode) - $($response.Content)"
    }
    Write-Verbose ($response | ConvertTo-Json -Depth 8)

    return Get-Property -Object ($response.Content | ConvertFrom-Json -Depth 8) -Property $Property
}