<#
    .SYNOPSIS
    Searches and returns a storage context from the Azure Resource Graph.

    .DESCRIPTION
    Searches and returns a storage context from the Azure Resource Graph. 
    For quickly aquiring a storage context and calling/testing storage tables, etc. via powershell.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Return a storage context for an storage account



    .LINK
        
#>
function Search-AzStorageContext {

    [Alias('STCtx')]
    param (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $StorageAccountName
    )

    $currentContext = Get-AzContext
    $StorageAccount = Search-AzStorageAccount -StorageAccountName $StorageAccountName
    if ($StorageAccount) {
        $null = Set-AzContext -Tenant $currentContext.Tenant -SubscriptionId $StorageAccount.subscriptionId
        $key = Get-AzStorageAccountKey -ResourceGroupName $StorageAccount.resourceGroup -Name $StorageAccount.name
        $ctx = New-AzStorageContext -StorageAccountName $StorageAccount.name -StorageAccountKey $key[0].Value
        $null = Set-AzContext -Context $currentContext
        return $ctx;
    }

}
