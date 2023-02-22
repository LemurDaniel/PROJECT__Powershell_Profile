<#
    .SYNOPSIS
    Searches and returns a function app resources from the Azure Resource Graph.

    .DESCRIPTION
    Searches and returns a function app resources from the Azure Resource Graph.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    A a single or a list of AzFunctionApp Powershell-Objects.



    .LINK
        
#>
function Search-AzFunctionApp {

    [CmdletBinding(
        DefaultParameterSetName = 'Take'
    )]
    param (
        # The Name the Function App must contain.
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [System.String[]]
        $FunctionAppName,

        # The Property to return from the items. If null will return full Properties.
        [Alias('return')]
        [Parameter()]
        [System.String]
        $Property,

        # The number of resources to return.
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'Take'
        )]
        [System.int32]
        $Take = 1,

        # Switch to return all results.
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'All'
        )]
        [switch]
        $All,

        # Switch to open them in the Azure Portal.
        [Parameter(Mandatory = $false)]
        [switch]
        $Browser
    )
    
    return Search-AzResource -Browser:$Browser -Property $Property -Take ($All ? 999 : $Take) -ResourceName $FunctionAppName -ResourceType 'microsoft.web/sites'

}