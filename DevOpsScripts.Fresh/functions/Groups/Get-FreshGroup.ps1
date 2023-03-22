function Get-FreshGroup {

    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $GroupId
    )

    return (Invoke-FreshApi -Method GET -ApiEndpoint groups -ApiResource ($GroupId -replace '[^\d]', '')).group
}
