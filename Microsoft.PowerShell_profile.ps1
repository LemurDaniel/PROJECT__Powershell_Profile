$ErrorActionPreference = 'Stop'

#net user administrator /active:yes
#net user administrator /active:no


###################################################################################

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$env:OneDrive = $env:OneDriveConsumer ?? $env:OneDrive

$env:TF_DATA_DIR = "C:\TFCACHE\$((Get-Location).path -split "\\" | Select-Object -Last 1)"
########################################################################################################################
########################################################################################################################
########################################################################################################################

<#
# CREDITS: Tim Krehan (tim.krehand@brz.eu)
#>
function Get-DumbJoke {

    param()

    return (Invoke-RestMethod -Method GET -Uri 'https://icanhazdadjoke.com/' -Headers @{'Accept' = 'application/json' }).joke

}




Import-Module "$PSScriptRoot\DevOpsScripts"
. "$PSScriptRoot/Environment.ps1"
 
# Switch-Terraform


$settingsFile = Get-Item -Path "$env:APPDATA/../Local/Packages/Microsoft.WindowsTerminal*/LocalState/settings.json" -ErrorAction SilentlyContinue
if ($settingsFile) {
    $settingsContent = Get-Content -Raw -Path "$PSScriptRoot/.resources/settings.json" | ConvertFrom-Json -Depth 99
    $settingsContent | ConvertTo-Json -Depth 99 | Out-File -FilePath $settingsFile.FullName
}

$gpgSigning = Read-SecureStringFromFile -Identifier gitGpgEnable -AsPlainText
while ($null -eq $gpgSigning -OR $gpgSigning.toLower() -notin ('true', 'false')) {
    $gpgSigning = Read-Host -Prompt 'Enable Gpg-Signing [true/false]'
    $null = git config --global commit.gpgsign $gpgSigning
    Save-SecureStringToFile -PlainText $gpgSigning -Identifier gitGpgEnable
}

if ([System.Boolean]::parse($gpgSigning)) {

    $gpg_id = Read-SecureStringFromFile -Identifier gitGpgId -AsPlainText 
    $gpg_grip = Read-SecureStringFromFile -Identifier gitGpgGrip -AsPlainText 
    $gpg_phrase = Read-SecureStringFromFile -Identifier gitGpgPhrase

    if (!$gpg_id -OR !$gpg_grip -OR !$gpg_phrase) {
        $gpg_id = Read-Host -Prompt 'Please Enter GPG Id'
        $gpg_grip = Read-Host -Prompt 'Please Enter GPG Grip'
        $gpg_phrase = Read-Host -AsSecureString -Prompt 'Please Enter GPG Phrase'

        Save-SecureStringToFile -PlainText $gpg_id -Identifier gitGpgId
        Save-SecureStringToFile -PlainText $gpg_grip -Identifier gitGpgGrip
        Save-SecureStringToFile -SecureString $gpg_phrase -Identifier gitGpgPhrase
    }

    # Overwrite settings for gpg-agent to set passphrase
    # Then Reload agent and set acutal Passphrase
    $gpgPath = $env:Path -Split ';' | Where-Object { $_ -like '*GnuPG*' } | Select-Object -First 1
    $null = git config --global --replace-all gpg.program "$gpgPath/gpg.exe"
    $null = git config --global --unset gpg.format
    $null = git config --global user.signingkey $gpg_id

    $gpgMainFolder = Get-ChildItem $env:APPDATA -Filter 'gnupg'
    @(
        'default-cache-ttl 345600'
        'max-cache-ttl 345600'
        'allow-preset-passphrase'
    ) -join "`r`n" | Out-File -FilePath "$($gpgMainFolder.FullName)/gpg-agent.conf"
    $null = gpgconf --kill gpg-agent # gpg-connect-agent reloadagent /bye
    $null = gpgconf --launch gpg-agent
    $null = $gpg_phrase | ConvertFrom-SecureString -AsPlainText | gpg-preset-passphrase --preset $gpg_grip


    $globalGitName = git config --global user.name 
    $globalGitMail = git config --global user.email

    if ($null -EQ $globalGitName) {
        $globalGitName = Read-Host -Prompt "Please Enter Global Git-Name"
        git config --global user.name $globalGitName
    }
    if ($null -EQ $globalGitMail) {
        $globalGitMail = Read-Host -Prompt "Please Enter Global Git-Email"
        git config --global user.email $globalGitMail
    }

    Write-Host 'Current Global Git Profile:'
    Write-Host "     $globalGitName"
    Write-Host "     $globalGitMail"
    Write-Host ''

    if ((Test-IsRepository)) {

        $localMail = git config --local user.email
        $localUser = git config --local user.name

        if ($localMail -AND $LocalUser) {

            Write-Host 'Current Local Git Profile:'
            Write-Host "    $localUser"
            Write-Host "    $localMail"
            Write-Host ''

        }

    }
}


Write-Host ''
Write-Host '  🤓 Joke of the Session 🤓'
Write-Host "  🎉 $(Get-DumbJoke)"
Write-Host '  👾 !!! Go Go Programming !!! 👾'
Write-Host ''