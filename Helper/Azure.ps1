

function Search-AzResource {
    param (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $ResourceName,
    
        [Parameter(Mandatory = $true)]
        [System.String]
        $ResourceType,

        [Parameter(Mandatory = $false)]
        [System.int32]
        $MaxReturnValues = 1
    )
    
    $query = "
        resources 
            | where tolower(type) =~ tolower('$ResourceType')
            | where name == name
    "

    foreach ($name in $ResourceName) {
        $query += "and name contains '$name'"
    }
    

    #-ManagementGroup ((Get-AzContext).Tenant.Id) 
    $results = (Search-AzGraph -Query $query)

    $resources = Get-PreferencedObject -SearchObjects $results -SearchTags $ResourceName -Multiple

    #$resources

    if ($resources[1]) {
        return $resources[0..($MaxReturnValues - 1)]
    }
    else {
        $resources[0]
    }

}

function Search-AzStorageAccount {
    param (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $StorageAccountName,

        [Parameter(Mandatory = $false)]
        [System.int32]
        $MaxReturnValues = 1
    )
    
    return Search-AzResource -ResourceName $StorageAccountName -ResourceType 'microsoft.storage/storageaccounts' -MaxReturnValues $MaxReturnValues 

}

function Search-AzFunctionApp {
    param (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $FunctionAppName
    )
    
    return Search-AzResource -ResourceName $FunctionAppName -ResourceType 'microsoft.web/sites'

}

function Search-AzFunctionAppConfiguration {

    [Alias('FAConf')]
    param (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $FunctionAppName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()] 
        $ConfigName
    )

    if ($ConfigName.GetType().Name -eq 'String') {
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

function Search-AzStorageAccountKey {

    [Alias('STkey')]
    param (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $StorageAccountName,

        [Parameter()]
        [ValidateSet('Key1', 'Key2', 'Both')]
        $KeySet = 'Key1'
    )

    $currentContext = Get-AzContext
    $StorageAccount = Search-AzStorageAccount -StorageAccountName $StorageAccountName
    if ($StorageAccount) {
        $null = Set-AzContext -Tenant $currentContext.Tenant -SubscriptionId $StorageAccount.subscriptionId
        $key = Get-AzStorageAccountKey -ResourceGroupName $StorageAccount.resourceGroup -Name $StorageAccount.name
        $null = Set-AzContext -Context $currentContext

        if ($KeySet -eq 'Key1') {
            return $key[0].Value
        }
        elseif ($KeySet -eq 'Key2') {
            return $key[1].Value
        }
        elseif ($KeySet -eq 'Both') {
            return $key
        }
    }
}




################################################################################


function Search-AzPermission {

    param (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Keys,

        [Parameter()]
        [ValidateSet([AzPermission])]
        $Provider = [AzPermission]::ALL,

        [Parameter()]
        [System.int32]
        $Limit = 7
    )


    $permissionsToSearch = [AzPermission]::GetPermissionsByProvider($Provider)

    return (Get-PreferencedObject -SearchObjects $permissionsToSearch -SearchTags $Keys -SearchProperty 'Operation Name' -Multiple)[0..($Limit - 1)]
}

function Search-AzRoleDefinitions {

    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [PSCustomObject[]]
        $Permissions
    )

    

}










#######################################################
############## Backup State





function Backup-AzState {
    param (
  
        [Parameter(Mandatory = $true)]
        [System.String]
        $Reason,

        [Parameter()]
        [System.String]
        [ValidateSet([AzTenant])]
        $Tenant = [AzTenant]::Default.Name
    
    )
    
    $StorageAccounts = Search-AzStorageAccount -StorageAccountName 'acfstate' -MaxReturnValues 5
  
    $TFSTATE_FOLDER = "$env:SECRET_STORE/TFSTATE"
    if (!(Test-Path $TFSTATE_FOLDER )) {
        New-Item -Type Directory -Path $TFSTATE_FOLDER 
    }
  
    
    $timeStamp = [DateTime]::Now
    $hasExistingFolders_atTimeStampe = (Get-ChildItem -Path $TFSTATE_FOLDER -Filter "*$($timeStamp.ToString('yyyy-MM-dd--HH-mm'))*" ).Count -gt 0
    if ($hasExistingFolders_atTimeStampe) {
        Write-Host -ForegroundColor RED "There was already an backup created today at: $($timeStamp.toString("HH:mm O`clock"))"
        return
    }
  
    
    $currentContext = Get-AzContext
    foreach ($StorageAccount in $StorageAccounts) {
        Write-Host -ForegroundColor GREEN "Backing up Storage Account: $($StorageAccount.name)"
  
        $Folder = New-Item -Type Directory -Path "$TFSTATE_FOLDER/$($timeStamp.ToString('yyyy-MM-dd--HH-mm'))---$($Reason.ToUpper())---$($StorageAccount.name)"
  
        $null = Set-AzContext -Tenant $currentContext.Tenant -SubscriptionId $StorageAccount.subscriptionId
        $key = Get-AzStorageAccountKey -ResourceGroupName $StorageAccount.resourceGroup -Name $StorageAccount.name
        $storageContext = New-AzStorageContext -StorageAccountName $StorageAccount.name -StorageAccountKey $key[0].Value
  
        foreach ($container in Get-AzStorageContainer -Context $storageContext) {
            Write-Host -ForegroundColor GREEN "   Backing up Container: $($container.name)"
            $FolderContainer = New-Item -Type Directory -Path "$($Folder.FullName)/$($container.Name)"
  
            try { 
                foreach ($blob in (Get-AzStorageBlob -Container $container.name -Context $storageContext | Where-Object { $null -eq $_.SnapshotTime })  ) {    
                    Write-Host -ForegroundColor GREEN "     Backing up Blob: $($blob.name)"
                    $blob | Get-AzStorageBlobContent -Context $storageContext -Destination "$($FolderContainer.FullName)/$($blob.name -replace ':', '_')" | Out-Null
                }
            }
            Catch {
                Write-Host -ForegroundColor RED $_
            }
    
        }
    }
    $null = Set-AzContext -Context $currentContext
    Write-Host -ForegroundColor GREEN 'FIN'
}


function Switch-AzTennant {

    param (
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [ValidateSet([AzTenant])]
        [System.String]
        $TennantName,

        [Parameter()]
        [switch]
        $NoDissconnect = $false
    )
    
    if (!$NoDissconnect) {
        Disconnect-AzAccount
    }
   
    $tenantId = [AzTenant]::GetTenantByName($TennantName).id
    Connect-AzAccount -Tenant $tenantId
}