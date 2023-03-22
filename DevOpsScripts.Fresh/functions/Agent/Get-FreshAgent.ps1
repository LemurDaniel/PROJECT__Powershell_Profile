function Get-FreshAgent {

    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $agentId
    )

    return (Invoke-FreshApi -Method GET -ApiEndpoint agents -ApiResource ($agentId -replace '[^\d]', ''))
}