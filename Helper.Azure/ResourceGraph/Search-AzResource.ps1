function Search-AzResource {
    param (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $ResourceName,
    
        [Parameter(Mandatory = $true)]
        [System.String]
        $ResourceType,

        [Parameter(Mandatory = $false)]
        [System.int32]
        $take = 1,

        [Parameter(Mandatory = $false)]
        [switch]
        $open
    )
    
    $query = "
        resources 
            | where tolower(type) =~ tolower('$ResourceType')
            | where name == name
    "

    foreach ($name in $ResourceName) {
        $query += "and name contains '$name'"
    }
    

    $results = (Search-AzGraph -Query $query) | ForEach-Object { $_ }
    $resources = Search-In $results -where 'name' -is $ResourceName -Multiple






    if ($resources.GetType().BaseType -eq [System.Array]) {
        $resources = $resources[0..($take - 1)]
    }

    if ($open) {
        $resources | ForEach-Object {
            Start-Process "https://portal.azure.com/#@$($_.tenantId)/resource/$($_.id)"
        }
    }

    return $resources
}