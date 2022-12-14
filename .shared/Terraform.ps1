function Get-TerraformVersion {

    param ( 
        [Parameter()]
        [System.String]
        $Version,

        [Parameter()]
        [switch]
        $Latest
    )

    if ($Latest) {

        if (!(terraform --version --json | ConvertFrom-Json).terraform_outdated) {
            return (Get-ChildItem -Path $env:TerraformPath -Directory | Sort-Object)[-1]
        } 
        else {
            $tfOutput = terraform --version
            $version = [regex]::Matches($tfOutput, '\d+\.{1}\d+\.{1}\d+')[1].Value
        }
    }

    Write-Verbose "Check Installation of v$version"
    $version = $Version.toLower()[0] -eq 'v' ? $version.Substring(1) : $version
    $TerraformFolder = Get-ChildItem -Path $env:TerraformPath -Filter "v$version"

    if ($TerraformFolder) {
        return $TerraformFolder
    }


    Write-Verbose "Get Downloadlink for Terraform Version v$version"
    $versions = (Invoke-WebRequest -Method GET -Uri $env:TerraformDownloadSource).Links.href | `
        Where-Object { $_ -match '^\/terraform\/\d{1,2}.\d{1,2}.\d{1,2}\/' }


    $newVersion = $versions[0].split('/')[2]
    if ($Version -ne 'latest') {
        $newVersion = ($versions | Where-Object { $_ -match $Version }).split('/')[2]
    }

    $downloadZipFile = "$env:USERPROFILE\downloads/terraform_$newVersion`_temp-$(Get-Random).zip"
    Invoke-WebRequest -Method GET -Uri "$env:TerraformDownloadSource$newVersion/terraform_$newVersion`_windows_amd64.zip" -OutFile $downloadZipFile

    $newTerraformFolder = Join-Path -Path $env:TerraformPath -ChildPath "/v$newVersion"
    $TerraformFolder = New-Item -ItemType directory $newTerraformFolder -Force

    $terraformZip = [System.IO.Compression.ZipFile]::OpenRead($downloadZipFile)
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($terraformZip.Entries[0], "$newTerraformFolder\terraform.exe", $true)

    return $TerraformFolder
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

    $TerraformFolder = Get-TerraformVersion -Version $Version
    Add-EnvPaths -RemovePaths @($env:TerraformPath) -AdditionalPaths @{
        Terraform = $($TerraformFolder.FullName)
    } 

    Write-Host
    terraform --version
    Write-Host
}


function Set-VersionActiveTF {

    [CmdletBinding()]
    param (
        [Parameter()]
        [System.String]
        $version
    )

    Update-SecretStore ORG -ENV -SecretPath CONFIG.TF_VERSION_ACTIVE -SecretValue $version

}