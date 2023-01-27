<#
    .SYNOPSIS
    Searches and returns a Resources from the Azure Resource Graph.

    .DESCRIPTION
    Searches and returns a Resources from the Azure Resource Graph.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    A a single or a list of Az Powershell-Objects.



    .LINK
        
#>
function Search-AzResource {
    param (
        # The Name the resource account must contain.
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $ResourceName,
    
        # The resource type.
        [Parameter(Mandatory = $true)]
        [System.String]
        $ResourceType,

        # The number of resources to return.
        [Parameter(Mandatory = $false)]
        [System.int32]
        $take = 1,

        # Switch to open them in the Azure Portal.
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