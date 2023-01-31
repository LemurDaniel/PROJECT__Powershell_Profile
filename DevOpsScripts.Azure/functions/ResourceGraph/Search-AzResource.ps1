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
        # The resource type.
        [Alias('where')]
        [Parameter(Mandatory = $true)]
        [System.String]
        $ResourceType,

        # The Name the resource account must contain.
        [Alias('is')]
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $ResourceName,

        # The number of resources to return.
        [Parameter(Mandatory = $false)]
        [System.int32]
        $Take = 1,

        # The Property to return from the items. If null will return full Properties.
        [Alias('return')]
        [Parameter()]
        [System.String]
        $Property,

        # Switch to open them in the Azure Portal.
        [Parameter(Mandatory = $false)]
        [switch]
        $Browser
    )

    $results = (Search-AzGraph -Query "
        resources 
            | where type =~ '$ResourceType'
            | where $( ($ResourceName | ForEach-Object { "name contains '$_'" }) -join ' and ' )
    ") | ForEach-Object { $_ }

    $resources = Search-In $results -where 'name' -has $ResourceName -Multiple

    if ($resources.GetType().BaseType -eq [System.Array]) {
        $resources = $resources[0..($take - 1)]
    }

    if ($Browser) {
        $resources | ForEach-Object {
            Start-Process "https://portal.azure.com/#@$($_.tenantId)/resource/$($_.id)"
        }
    }

    return Get-Property -Object $resources -Property $Property
}