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
    param (
        # The Name the Function App must contain.
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $FunctionAppName,

        # Switch to open them in the Azure Portal.
        [Parameter(Mandatory = $false)]
        [switch]
        $open
    )
    
    return Search-AzResource -open:$open -ResourceName $FunctionAppName -ResourceType 'microsoft.web/sites'

}