function Get-TerraformNewestVersion {

    param ( [Parameter()]
        [System.String]
        $Version = 'latest'
    )

    if ($Version -eq 'latest' -AND (!(terraform --version --json | ConvertFrom-Json).terraform_outdated)) {
        return
    }
    
    $versions = (Invoke-WebRequest -Method GET -Uri $env:TerraformDownloadSource).Links.href `
    | Where-Object { $_ -match '^\/terraform\/\d{1,2}.\d{1,2}.\d{1,2}\/' }

    $newVersion = $versions[0].split('/')[2]
    if ($Version -ne 'latest') {
        Write-Host $Version
        $newVersion = ($versions | Where-Object { $_ -match $Version }).split('/')[2]
    }

    $downloadZipFile = "$env:USERPROFILE\downloads/terraform_$newVersion`_temp-$(Get-Random).zip"
    Invoke-WebRequest -Method GET -Uri "$env:TerraformDownloadSource$newVersion/terraform_$newVersion`_windows_amd64.zip" -OutFile $downloadZipFile

    $newTerraformFolder = Join-Path -Path $env:TerraformPath -ChildPath "/v$newVersion"
    if (!(Test-Path -Path $newTerraformFolder)) {
        New-Item -ItemType directory $newTerraformFolder -Force
    }

    $terraformZip = [System.IO.Compression.ZipFile]::OpenRead($downloadZipFile)
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($terraformZip.Entries[0], "$newTerraformFolder\terraform.exe", $true)

}

function Switch-Terraform {

    [Alias('tf')]
    param (
        [Parameter()]
        [System.String]
        $Version = 'latest'
    )
    
    if ($Version -ne 'latest' -And $Version.ToLower()[0] -ne 'v') {
        $Version = "v$Version"
    }

    if ($Version.Length -eq 2 -and $Version.ToLower()[0] -eq 'v' -and '0123456789'.Contains($Version[1])) {
        $Version = "v1.1.$($Version[1])"
    }

    # Latest
    $TerraformFolder = $null

    if ($Version -and $Version.ToLower() -ne 'latest') {
        Write-Host (Get-ChildItem -Path $env:TerraformPath -Directory -Filter $Version)
        $TerraformFolder = (Get-ChildItem -Path $env:TerraformPath -Directory -Filter $Version)
    }
    else {
        $TerraformFolder = (Get-ChildItem -Path $env:TerraformPath -Directory | Sort-Object -Property Name -Descending)[0]
    }

    if ( $null -eq $TerraformFolder) {
        Get-TerraformNewestVersion -Version ($Version[1..$Version.Length] -join '')
        $TerraformFolder = (Get-ChildItem -Path $env:TerraformPath -Directory -Filter $Version)
    }

    # Write-Host $TerraformFolder
    Add-EnvPaths -RemovePaths @($env:TerraformPath) -AdditionalPaths @{
        Terraform = $($TerraformFolder.FullName)
    } 

    Write-Host
    terraform --version
    Write-Host
}