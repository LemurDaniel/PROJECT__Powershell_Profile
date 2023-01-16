function Search-AzFunctionApp {
    param (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $FunctionAppName,

        [Parameter(Mandatory = $false)]
        [switch]
        $open
    )
    
    return Search-AzResource -open:$open -ResourceName $FunctionAppName -ResourceType 'microsoft.web/sites'

}