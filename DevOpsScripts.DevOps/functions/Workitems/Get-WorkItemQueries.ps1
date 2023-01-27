
<#
    .SYNOPSIS
    Gets all Workitem Queries in Azure DevOps accesible by the user.

    .DESCRIPTION
    Gets all Workitem Queries in Azure DevOps accesible by the user. Own and Shared.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    List of all Workitem Queries accessible by the user.


    .EXAMPLE

    Get a List of all Work-Item Queries:

    PS> Get-WorkItemQueries

    .EXAMPLE

    Get a List of the Names of all Work-Item Queries:

    PS> Get-WorkItemQueries 'name'

    .LINK
        
#>
function Get-WorkItemQueries {
    param (

        # The Property to return from the items. If null will return full Properties.
        [Alias('return')]
        [Parameter()]
        [System.String]
        $Property
    )

    $Queries = Get-AzureDevOpsCache -Type Queries -Identifier 'all'

    if(!$Queries){
    $Request = @{
        Method = 'GET'
        Domain = 'dev.azure'
        Call   = 'Proj'
        API    = '/_apis/wit/queries?$depth=1&api-version=7.1-preview.2'
    }
    $response = Invoke-DevOpsRest @Request -return 'Value.Children'
    $Queries = Set-AzureDevOpsCache -Object $response -Type Queries -Identifier 'all' -Alive 10
}

return Get-Property -Object $Queries -Property $Property
}