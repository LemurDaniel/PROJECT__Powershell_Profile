
function Search-AzStorageAccount {
    param (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $StorageAccountName,

        [Parameter(Mandatory = $false)]
        [System.int32]
        $take = 1,

        [Parameter(Mandatory = $false)]
        [switch]
        $open
    )
    
    return Search-AzResource -open:$open -ResourceName $StorageAccountName -ResourceType 'microsoft.storage/storageaccounts' -take $take 

}