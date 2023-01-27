<#
    .SYNOPSIS
    Searches and returns a storage account from the Azure Resource Graph.

    .DESCRIPTION
    Searches and returns a storage account resources from the Azure Resource Graph.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    A a single or a list of AzStorageAccount Powershell-Objects.



    .LINK
        
#>
function Search-AzStorageAccount {
    param (
        # The Name the storage account must contain.
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $StorageAccountName,

        # The number of storage accounts to return.
        [Parameter(Mandatory = $false)]
        [System.int32]
        $take = 1,

        # Switch to open them in the Azure Portal.
        [Parameter(Mandatory = $false)]
        [switch]
        $open
    )
    
    return Search-AzResource -open:$open -ResourceName $StorageAccountName -ResourceType 'microsoft.storage/storageaccounts' -take $take 

}