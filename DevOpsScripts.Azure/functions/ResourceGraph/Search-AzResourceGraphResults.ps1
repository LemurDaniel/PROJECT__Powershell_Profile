

<#
    .SYNOPSIS
    Returns all results beyond the 1000-Query Limit. Can be set to a custom amount like 2100, etc.

    .DESCRIPTION
    Returns all results beyond the 1000-Query Limit. Can be set to a custom amount like 2100, etc.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Return the result of the Az Resource Graph Query.


    .EXAMPLE

    Return up to the first 2100 Resources:

    PS> $data = Search-AzResourceGraphResults -Returnlimit 2100 -Query "resources" -Verbose
    PS> $data.Count # Equal to or less than 2100.

    .LINK

    https://learn.microsoft.com/en-us/azure/governance/resource-graph/concepts/work-with-data#paging-results

    When it's necessary to break a result set into smaller sets of records for processing 
    or because a result set would exceed the maximum allowed value of 1000 returned records, use paging.

#>

function Search-AzResourceGraphResults {

    [CmdletBinding()]
    [OutputType([System.Array])]
    param (
        # The Resource Graph Query.
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $Query,

        # The Management Group Scope. Will default to root management group.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $ManagementGroup,

        # The Total-Limit of Resource to return.
        [Parameter(
            Mandatory = $false
        )]
        [ValidateRange(1, [System.Int32]::MaxValue)]
        $Returnlimit = [System.Int32]::MaxValue
    )

    $ManagementGroup = [System.String]::IsNullOrEmpty($ManagementGroup) ? (Get-AzContext).Tenant.Id : $ManagementGroup
    $QueryResults = @()
    $QueryLimit = 1000
    $SkipAmount = 0 

    do {

        $GraphQuery = @{
            ManagementGroup = $ManagementGroup 
            Query           = $Query 
            First           = $QueryLimit
        }

        if ($SkipAmount -gt 0) {
            $GraphQuery.Skip = $SkipAmount
        }

        # Limit the query result by the maximum return limit, if required.
        if (($Returnlimit - $QueryResults.Count) -lt $QueryLimit) {
            $GraphQuery.First = $Returnlimit - $QueryResults.Count
        }

        Write-Verbose ($GraphQuery | ConvertTo-Json) 

        $QueryResponse = Search-AzGraph @GraphQuery 
        $SkipAmount += $QueryLimit
        $QueryResults += $QueryResponse.Data

    }
    while ($null -ne $QueryResponse.SkipToken -AND $QueryResults.Count -lt $Returnlimit)

    return , $QueryResults
}