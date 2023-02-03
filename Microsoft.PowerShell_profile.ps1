$ErrorActionPreference = 'Stop'

#net user administrator /active:yes
#net user administrator /active:no


# NPM config globals  npm install -g azure-functions-core-tools@4 --unsafe-perm true

###################################################################################

## Resolve App Path
$env:OneDrive = $env:OneDriveConsumer ?? $env:OneDrive
$env:AppPath = "$env:OneDrive/_Apps/"
$env:AppPathSecondary = "$env:OneDrive/Dokumente/_Apps"
if (!(Test-Path $env:AppPath)) {
    $env:AppPath = (Resolve-Path $env:AppPathSecondary).Path
}

## ENV Variables
$env:SECRET_STORE = "$env:AppPath/_SECRET_STORE/"
$env:Secondary_SECRET_STORE = "$env:APPDATA/_SECRET_TOKEN_STORE/"
if (!(Test-Path $env:SECRET_STORE)) {
    $env:SECRET_STORE = (Resolve-Path $env:Secondary_SECRET_STORE).Path
}

### Resolve Terraform Path
$env:TerraformDocs = (Resolve-Path "$env:AppPath/_EnvPath_Apps/terraform-docs/").Path
$env:TerraformPath = (Resolve-Path "$env:AppPath/_EnvPath_Apps/terraform/").Path
$env:TerraformNewestVersion = (Get-ChildItem -Path $env:TerraformPath | Sort-Object -Descending)[0].FullName
$env:TerraformDocsNewestVersion = (Get-ChildItem -Path $env:TerraformDocs | Sort-Object -Descending)[0].FullName

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
. "$PSScriptRoot/Other.ps1"
 

Get-SecretsFromStore -Show
Add-EnvPaths


$null = Switch-Terraform
$activeVersionTF = Get-UtilsCache -Type TerraformVersion -Identifier Current
if ($activeVersionTF) {
    Switch-Terraform -TFVersion $activeVersionTF
} 

$null = Add-QuickContext -ContextName Teamsbuilder -Organization baugruppe -Project 'Teamsbuilder' -Force
$null = Add-QuickContext -ContextName 'DC Migration' -Organization baugruppe -Project 'DC Azure Migration' -Force
$null = Add-QuickContext -ContextName 'DC Redeploy' -Organization baugruppe -Project 'DC ACF Redeployment' -Force


$null = Add-PimProfile -ProfileName WebContrib -Scope 'managementGroups/acfroot-prod' -Role 'Website Contributor' -duration 3 -Force
$null = Add-PimProfile -ProfileName PolicyContrib -Scope 'managementGroups/acfroot-prod' -Role 'Resource Policy Contributor' -duration 3 -Force

Set-Item -Path env:TF_DATA_DIR -Value 'C:\TFCACHE'




$gpgSigning = $true

if($gpgSigning){

    $gpg_id = Read-SecureStringFromFile -Identifier gitGpgId -AsPlainText 
    $gpg_grip = Read-SecureStringFromFile -Identifier gitGpgGrip -AsPlainText 
    $gpg_phrase = Read-SecureStringFromFile -Identifier gitGpgPhrase -AsPlainText 

    if(!$gpg_id -OR !$gpg_grip -OR !$gpg_phrase){
        $gpg_id     = Read-Host -Prompt "Pleasse Enter GPG Id"
        $gpg_grip   = Read-Host -Prompt "Pleasse Enter GPG Grip"
        $gpg_phrase = Read-Host -Prompt "Pleasse Enter GPG Phrase"

        Save-SecureStringToFile -PlaintText $gpg_id -Identifier gitGpgId
        Save-SecureStringToFile -PlaintText $gpg_grip -Identifier gitGpgGrip
        Save-SecureStringToFile -PlaintText $gpg_phrase -Identifier gitGpgPhrase
    }

    # Overwrite settings for gpg-agent to set passphrase
    # Then Reload agent and set acutal Passphrase
    $null = git config --global gpg.program "$($global:DefaultEnvPaths['gpg'])/gpg.exe"
    $null = git config --global --unset gpg.format
    $null = git config --global user.signingkey $env:gpg_id   

    $gpgMainFolder = Get-ChildItem $env:APPDATA -Filter 'gnupg'
    @(
        'default-cache-ttl 345600'
        'max-cache-ttl 345600'
        'allow-preset-passphrase'
    ) -join "`r`n" | Out-File -FilePath "$($gpgMainFolder.FullName)/gpg-agent.conf"
    $null = gpgconf --kill gpg-agent #gpg-connect-agent reloadagent /bye
    $null = gpgconf --launch gpg-agent
    $null = $env:gpg_phrase | gpg-preset-passphrase --preset $env:gpg_grip

    Write-Host 'Current Global Git Profile:'
    Write-Host "    $(git config --global user.name )"
    Write-Host "    $(git config --global user.email )"
    Write-Host ''

    git -C . rev-parse >nul 2>&1; 
    if ($?) {

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