
<#
.SYNOPSIS
    Back up the contents of azure storage tables into a CSV-files.

.DESCRIPTION
    Back up the contents of azure storage tables into a CSV-files.

.EXAMPLE
    Back up the contents of all tables of a storage account into a CSV-files:

    PS> Backup-AzTables `
        -BackupFolder "C:\myBackupLocation" `
        -StorageAccountName "myStorageAccount" `
        -storageAccountKey "myStorageAccountKey"

.LINK
  

#>
function Backup-AzTables {
    param (
        # Location where the CSV-files are saved.
        [Parameter(Mandatory = $true)] [System.String] $BackupFolder,

        # Name of the storage account whose tables are backed up.
        [Parameter(Mandatory = $true)] [System.String] $StorageAccountName,

        # The storage account key of the storage account.
        [Parameter(Mandatory = $true)] [System.String] $StorageAccountKey
    )

    # CEST datetime
    $utcDate = (Get-Date).ToUniversalTime()
    $tzCEST = [System.TimeZoneInfo]::FindSystemTimeZoneById("W. Europe Standard Time")
    $currentDateTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($utcDate, $tzCEST)
    $currentDate = $currentDateTime.Date.ToString('yyyy-MM-dd');
    
    $ctx = New-AzStorageContext $StorageAccountName -StorageAccountKey $StorageAccountKey
    $cloudTables = Get-AzStorageTable -Context $ctx | Sort-Object -Property "CloudTable" | ForEach-Object { $_.CloudTable }
        
    Write-Host -ForegroundColor Green "Creating Backup of storage Account $ctx | Current Date: $currentDate"
 
    if (!(Test-Path $BackupFolder)) {
        $null = New-Item -ItemType Directory -Path $BackupFolder
        Write-Host ("       Creating folder @ '$BackupFolder'") -ForegroundColor Yellow
    }


    foreach ($cloudTable in $cloudTables) {
     
        $fileName = $currentDate + "--" + $cloudTable.Name + '.csv';
        $backupPath = Join-Path $BackupFolder $fileName

        Write-Host -ForegroundColor Yellow "     Create Backup for Table '$($cloudTable.Name)' @ '$backupPath'"
        
        Get-AzTableRow -table $cloudTable | Export-Csv -Path $backupPath
    }

}
