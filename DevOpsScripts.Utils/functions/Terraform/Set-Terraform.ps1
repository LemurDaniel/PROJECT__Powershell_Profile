<#
    .SYNOPSIS
    Switches the current Terraform Version.

    .DESCRIPTION
    Switches the current Terraform Version.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None.


    .EXAMPLE

    Set specific terraform version across all powershell sessions:

    PS> tf 1.5.3


    .EXAMPLE

    Set newest terraform version only in the current powershell session:

    PS> tf -SessionOnly


    .EXAMPLE

    Set specific terraform version only in the current powershell session:

    PS> tf -SessionOnly 1.5.4

    .LINK
        
#>


function Set-Terraform {
    
    [Alias('tf')]
    [CmdletBinding()]
    param (

        # Include alpha and beta version on the autocompletion
        [Parameter(
            Position = 1,
            Mandatory = $false
        )]
        [switch]
        $Alpha,

        [Parameter(
            Position = 0,
            Mandatory = $false
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                return (Get-TerraformVersions -Alpha:$fakeBoundParameters['Alpha']).Version
            }
        )]
        [System.String]
        $Version,


        # Only change in current powershell session. Download if necessaray.
        [Parameter(
            Position = 2
        )]
        [switch]
        $SessionOnly
    )

    # Define and create folders.
    $TerraformVersionFolder = (![System.String]::isNullOrEmpty($env:TerraformPath) ? $env:TerraformPath : "$env:USERPROFILE\terraform")
    $TerraformActiveFolder = "$TerraformVersionFolder\active"

    if (!$env:Path.Contains($TerraformActiveFolder)) {
        $env:Path = $TerraformActiveFolder + ';' + $env:Path
    }

    # Set permanently in user path
    $UserEnvironmentPaths = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::User) 
    if (!$UserEnvironmentPaths.Contains($TerraformActiveFolder)) {
        $UserEnvironmentPaths = ($UserEnvironmentPaths -split ';' | Where-Object { $_.Length -gt 0 }) -join ';'
        $UserEnvironmentPaths = $TerraformActiveFolder + ';' + $UserEnvironmentPaths
        [System.Environment]::SetEnvironmentVariable('Path', $UserEnvironmentPaths, [System.EnvironmentVariableTarget]::User)
    }

    if (!(Test-Path $TerraformVersionFolder)) {
        $TerraformVersionFolder = New-Item -ItemType Directory -Path $TerraformVersionFolder
    }
    else {
        $TerraformVersionFolder = Get-Item -Path $TerraformVersionFolder
    }

    if (!(Test-Path $TerraformActiveFolder)) {
        $TerraformActiveFolder = New-Item -ItemType Directory -Path $TerraformActiveFolder
    }
    else {
        $TerraformActiveFolder = Get-Item -Path $TerraformActiveFolder
    }


    # Select newest version on null.
    if ([string]::IsNullOrEmpty($Version)) {
        $Version = Get-TerraformVersions 
        | Where-Object -Property Version
        | Select-Object -First 1 -ExpandProperty Version
    }


    # Check if selected version already exists locally
    $targetSubfolder = Get-ChildItem -Path $TerraformVersionFolder -Filter "v$Version"
    if ($null -EQ $targetSubfolder) {
        $targetSubfolder = New-Item -ItemType Directory -Path "$TerraformVersionFolder/v$Version"
    }

    # Donwload version if not present locally.
    $targetZip = Get-ChildItem -Path $targetSubfolder.FullName -Filter "terraform.zip"
    $targetExe = Get-ChildItem -Path $targetSubfolder.FullName -Filter "terraform.exe"
    if ($null -EQ $targetExe) {
        $remoteTarget = Get-TerraformVersions -Alpha:$Alpha | Where-Object -Property Version -EQ $Version
        Invoke-WebRequest -Method GET -Uri $remoteTarget.windows_amd64 -OutFile "$targetSubfolder/terraform.zip"
        $terraformZip = [System.IO.Compression.ZipFile]::OpenRead("$targetSubfolder/terraform.zip")
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($terraformZip.Entries[0], "$targetSubfolder/terraform.exe", $true)
        $targetZip = Get-ChildItem -Path $targetSubfolder.FullName -Filter "terraform.zip"
    }

    
    if ($SessionOnly) {
        $regexExp = "$($TerraformVersionFolder.FullName.replace('\', '\\'))[\\]*v*"
        $environmentPaths = $env:Path -split ';' | Where-Object { $_ -notMatch $regexExp } | Where-Object { $_.Length -gt 0 }
        $environmentPaths = $environmentPaths -join ';'
        $env:Path = $targetSubfolder.FullName + ";" + $environmentPaths
    }
    else {
        $terraformExists = (Get-Command -Name 'terraform' -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
        $terraformOutdated = $terraformExists -AND (terraform --version --json | ConvertFrom-Json).terraform_version -ne $Version
        if (!$terraformExists -OR $terraformOutdated) {
            $terraformZip = [System.IO.Compression.ZipFile]::OpenRead($targetZip.FullName)
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($terraformZip.Entries[0], "$TerraformActiveFolder/terraform.exe", $true)
        }
    }

    Write-Host 
    terraform --version
    Write-Host

}