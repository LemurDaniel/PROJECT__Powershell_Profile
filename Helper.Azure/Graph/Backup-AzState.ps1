function Backup-AzState {

    [CmdletBinding()]
    param (
        [Parameter()]
        [System.String[]]
        $SeachTags = 'acfstate'
  
    )

    DynamicParam {
        $AttributCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
        $ParameterAttribute = [System.Management.Automation.ParameterAttribute]::new()
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.DontShow = $false
        $ParameterAttribute.Position = 0
        $ParameterAttribute.ParameterSetName = 'tenant'
        $ParameterAttribute.ValueFromPipeline = $false
        $ParameterAttribute.ValueFromPipelineByPropertyName = $false
        $ParameterAttribute.ValueFromRemainingArguments = $false
        $AttributCollection.Add($ParameterAttribute)
  
        $tenants = Get-AzTenant
        $ValidateSetOptions = [String[]]($tenants.Name | Sort-Object -Property name)
        $AttributCollection.Add((New-Object System.Management.Automation.ValidateSetAttribute($ValidateSetOptions)))
        $RunTimeParameter = [System.Management.Automation.RuntimeDefinedParameter]::new('Tenant', [System.String], $AttributCollection)
        $RuntimeParamDic = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
        $RuntimeParamDic.Add('Tenant', $RunTimeParameter)

        return $RuntimeParamDic
    }
 
    Begin {
        Connect-AzAccount -Tenant ($tenants | Where-Object -Property Name -EQ -Value $Tenant).id
        $StorageAccounts = Search-AzStorageAccount -StorageAccountName $searchTags -MaxReturnValues 5

        $TFSTATE_FOLDER = "$env:SECRET_STORE/TFSTATE"
        if (!(Test-Path $TFSTATE_FOLDER )) {
            New-Item -Type Directory -Path $TFSTATE_FOLDER 
        }

    }
    process {
        $timeStamp = [DateTime]::Now
        $hasExistingFolders_atTimeStampe = (Get-ChildItem -Path $TFSTATE_FOLDER -Filter "*$($timeStamp.ToString('yyyy-MM-dd--HH-mm'))" ).Count -gt 0
        if ($hasExistingFolders_atTimeStampe) {
            Write-Host -ForegroundColor RED "There was already an backup created today at: $($timeStamp.toString("HH:mm O`clock"))"
            return
        }

  
        $currentContext = Get-AzContext
        foreach ($StorageAccount in $StorageAccounts) {
            Write-Host -ForegroundColor GREEN "Backing up Storage Account: $($StorageAccount.name)"

            $Folder = New-Item -Type Directory -Path "$TFSTATE_FOLDER/$($StorageAccount.name)-$($timeStamp.ToString('yyyy-MM-dd--HH-mm'))"

            $null = Set-AzContext -Tenant $currentContext.Tenant -SubscriptionId $StorageAccount.subscriptionId
            $key = Get-AzStorageAccountKey -ResourceGroupName $StorageAccount.resourceGroup -Name $StorageAccount.name
            $storageContext = New-AzStorageContext -StorageAccountName $StorageAccount.name -StorageAccountKey $key[0].Value

            foreach ($container in Get-AzStorageContainer -Context $storageContext) {
                Write-Host -ForegroundColor GREEN "   Backing up Container: $($container.name)"
                $FolderContainer = New-Item -Type Directory -Path "$($Folder.FullName)/$($container.Name)"

                try { 
                    foreach ($blob in (Get-AzStorageBlob -Container $ct[2].name -Context $stctx | Where-Object { $null -eq $_.SnapshotTime })  ) {    
                        Write-Host -ForegroundColor GREEN "     Backing up Blob: $($blob.name)"
                        $null = Out-File -FilePath "$($FolderContainer.FullName)/$($blob.name)"
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
    end {}
}

