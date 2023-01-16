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
