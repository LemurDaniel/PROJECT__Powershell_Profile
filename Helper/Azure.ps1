

function Search-AzResource {
    param (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $ResourceName,
    
        [Parameter(Mandatory = $true)]
        [System.String]
        $ResourceType
    )
    
    $query = "
        resources 
            | where type =~ '$ResourceType'
            | where name contains '' 
    "

    foreach ($name in $ResourceName) {
        $query += "or name contains '$name'"
    }
    
    $results = [System.Collections.ArrayList]::new()
    foreach ($result in (Search-AzGraph -ManagementGroup (Get-AzContext).Tenant.Id -Query $query)) {
        $null = $results.Add($result)
    }

    return Get-PreferencedObject -SearchObjects $results -SearchTags $ResourceName   
}

function Search-AzStorageAccount {
    param (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $StorageAccountName
    )
    
    return Search-AzResource -ResourceName $StorageAccountName -ResourceType "microsoft.storage/storageaccounts"

}

function Search-AzFunctionApp {
    param (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $FunctionAppName
    )
    
    return Search-AzResource -ResourceName $FunctionAppName -ResourceType "microsoft.web/sites"

}

function Search-AzFunctionAppConfiguration {

    [Alias("FAConf")]
    param (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $FunctionAppName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()] 
        $ConfigName
    )

    if ($ConfigName.GetType().Name -eq "String") {
        $ConfigName = @( $ConfigName )
    }
    $FunctionApp = Search-AzFunctionApp -FunctionAppName $FunctionAppName
    if ($FunctionApp) {

        Write-Host "https://management.azure.com$($FunctionApp.ResourceId)/config/appsettings/list?api-version=2021-02-01"
        $response = Invoke-AzRestMethod -Method POST -Uri "https://management.azure.com$($FunctionApp.ResourceId)/config/appsettings/list?api-version=2021-02-01"
        $AppSettings = [System.Collections.ArrayList]::new()
        ($response.Content | ConvertFrom-Json).properties.PSObject.Properties | ForEach-Object { $null = $AppSettings.Add($_) }
        return Get-PreferencedObject -SearchObjects $Appsettings -SearchTags $ConfigName
    }

}

function Search-AzStorageAccountContext {

    [Alias("STCtx")]
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

function Search-AzStorageAccountKey {

    [Alias("STkey")]
    param (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $StorageAccountName,

        [Parameter()]
        [ValidateSet("Key1", "Key2", "Both")]
        $KeySet = "Key1"
    )

    $currentContext = Get-AzContext
    $StorageAccount = Search-AzStorageAccount -StorageAccountName $StorageAccountName
    if ($StorageAccount) {
        $null = Set-AzContext -Tenant $currentContext.Tenant -SubscriptionId $StorageAccount.subscriptionId
        $key = Get-AzStorageAccountKey -ResourceGroupName $StorageAccount.resourceGroup -Name $StorageAccount.name
        $null = Set-AzContext -Context $currentContext

        if ($KeySet -eq "Key1") {
            return $key[0].Value
        }
        elseif ($KeySet -eq "Key2") {
            return $key[1].Value
        }
        elseif ($KeySet -eq "Both") {
            return $key
        }
    }
}

