function Search-AzVm {
    param (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $FunctionAppName,

        [Parameter(Mandatory = $false)]
        [System.int32]
        $take = 1,

        [Parameter(Mandatory = $false)]
        [switch]
        $open
    )
    
    return Search-AzResource -open:$open -take $take -ResourceName $FunctionAppName -ResourceType 'microsoft.compute/virtualmachines'

}