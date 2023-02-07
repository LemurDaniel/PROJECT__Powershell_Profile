<#
    .SYNOPSIS
        Restore CSV-file backup into storage tables.

    .DESCRIPTION
        Restore CSV-file backup into storage tables.

    .EXAMPLE
        Restore the latest backups into a storage account:

        PS> Restore-AzTables `
                -BackupFolder "C:\myBackupLocation" `
                -StorageAccountName "myStorageAccount" `
                -storageAccountKey "myStorageAccountKey" `


    .EXAMPLE
        Restore the backups of a certain day into a storage account:

        PS> Restore-AzTables `
                -BackupFolder "C:\myBackupLocation" `
                -StorageAccountName "myStorageAccount" `
                -storageAccountKey "myStorageAccountKey" `
                -BackupDate "2022.01.25" `


    .LINK
     

#>

function Restore-AzTables {
 
    param (
        # The location where the backup files are stored
        [parameter(Mandatory = $true)] 
        [System.String] $BackupPath,

        # The storage account to restore the tables into
        [parameter(Mandatory = $true)] 
        [System.String] $StorageAccountNameRestore,

        # The storage account key for the storage account
        [Parameter(Mandatory = $true)] 
        [System.String] $StorageAccountNameRestoreKey,

        # The date of the backups. Chooses latest backups if null.
        [parameter()] 
        [System.String] $BackupDate,
        
        # A postifx for the restored tablenames.
        [parameter()] 
        [System.String] $RestoredTablePostfix,

        # Force the overwriting of existing table data.
        [Parameter()] 
        [System.Boolean] $Force = $false
    )



    $BackupFiles = Get-ChildItem -Path  $BackupPath | Sort-Object -Property Name -Descending

    if ($BackupDate -eq $null) {
        $BackupDate = ($BackupFiles[0].Name -split '--')[0];
    }
    else {
        $BackupDate = ([System.Datetime] $BackupDate).toString("yyyy-MM-dd");
    }

    # Filter down all backup files to the specific date.
    $BackupFiles = $BackupFiles | Where-Object { $_.Name -like "$BackupDate*" };
    if ($BackupFiles.Length -eq 0) {
        return Write-Error "There are no existing backup files for the date '$BackupDate' @ '$BackupPath'"
    }



    $storageAccountContext = New-AzStorageContext -StorageAccountName $StorageAccountNameRestore -StorageAccountKey $StorageAccountNameRestoreKey; 
    foreach ($BackupFile in $BackupFiles) { 

        # Create tablename from filename and append optional postfix for restored tables.
        $RestoreTableName = (($BackupFile.Name -split '--')[1] -replace ".csv") + $RestoredTablePostfix

        $storageTable = Get-AzStorageTable -Context $storageAccountContext -Name $RestoreTableName -ErrorVariable doesNotExist -ErrorAction SilentlyContinue -Verbose:$false;
        Write-Host -ForegroundColor Yellow "Restoring '$($BackupFile.Name)' as '$RestoreTableName' @ '$($storageAccountContext.TableEndPoint)'"

        # Create new table if non-existent.
        if ($doesNotExist) {
            $storageTable = New-AzStorageTable -Context $storageAccountContext -Name $RestoreTableName -Verbose:$false
        } 
        # Delete all existing data on force.
        elseif ($Force) {
            $null = Get-AzTableRow -table $storageTable.CloudTable -Verbose:$false | Remove-AzTableRow -table $storageTable.CloudTable -Verbose:$false;
        }
        # Ask for confirmation to replace data in existing table, to prevent data loss.
        else {
            Write-Host -ForegroundColor Red "[WARNING] Data loss may occurr!"
            Write-Host -ForegroundColor Red "[WARNING] The table '$RestoreTableName' already exists!"
            Write-Host -NoNewLine -ForegroundColor Red "[WARNING] Do you want to replace all data in it? "
            $Confirmation = Read-Host -Prompt "[Yes/No]"

            if ($Confirmation.toLower() -eq "yes") {
                Write-Host -ForegroundColor Yellow "[WARNING] Deleting existing data in '$RestoreTableName'";
                $null = Get-AzTableRow -table $storageTable.CloudTable -Verbose:$false | Remove-AzTableRow -table $storageTable.CloudTable -Verbose:$false;
            }
            else {
                Write-Host -ForegroundColor Yellow "[INORMATION] Skipping table restoration for '$RestoreTableName' `n";
                continue;
            }
        }
        
    
        Write-Host -ForegroundColor Green "[INORMATION] Restoring backup into '$RestoreTableName' `n";
        foreach ($row in (Import-Csv -Path $BackupFile)) {

            $PartitionKey = $row.PartitionKey;
            $RowKey = $row.RowKey;

            $row.PSObject.Properties.remove("TableTimestamp")
            $row.PSObject.Properties.remove("PartitionKey")
            $row.PSObject.Properties.remove("RowKey")
            $row.PSObject.Properties.remove("Etag")


            $rowHashtable = [System.Collections.Hashtable]::new();
            $row.PSObject.Properties | ForEach-Object { $rowHashtable[$_.Name] = $_.Value }

            $null = Add-AzTableRow `
                -table ($storageTable.CloudTable) `
                -partitionKey $PartitionKey `
                -rowKey $RowKey `
                -property $rowHashtable `
                -Verbose:$false
        }
        
    }
}
