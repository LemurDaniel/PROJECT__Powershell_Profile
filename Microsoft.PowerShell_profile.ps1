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
if($activeVersionTF) {
    Switch-Terraform -TFVersion $activeVersionTF
} 


Set-Item -Path env:TF_DATA_DIR -Value 'C:\TFCACHE'
Switch-GitConfig -config ($env:USERNAME -eq 'M01947' ? 'brz' : 'git')


Write-Host ''
Write-Host '  🤓 Joke of the Session 🤓'
Write-Host "  🎉 $(Get-DumbJoke)"
Write-Host '  👾 !!! Go Go Programming !!! 👾'
Write-Host ''