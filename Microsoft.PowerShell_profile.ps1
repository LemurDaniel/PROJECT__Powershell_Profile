$ErrorActionPreference = "Stop"

#net user administrator /active:yes
#net user administrator /active:no


# NPM config globals  npm install -g azure-functions-core-tools@4 --unsafe-perm true

###################################################################################

$env:PS_PROFILE = $PROFILE
$env:PS_PROFILE_PATH = (Resolve-Path "$env:PS_PROFILE\..").Path
$env:PROFILE_HELPERS_PATH = (Resolve-Path "$env:PS_PROFILE_PATH\.shared").Path


## Same entry also exists in ONEDRIVE/Powershell/7/profile.ps1
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


$env:SECRET_PERMISSIONS = (Resolve-Path "$env:SECRET_STORE/PERMISSION_ACTIONS.csv" -ErrorAction Continue)
$env:ROLE_DEFINITIONS = (Resolve-Path "$env:SECRET_STORE/ROLE_DEFINITONS.json" -ErrorAction Continue) 

if ($null -eq $env:ROLE_DEFINITIONS) {
  $roleDefinitions_DEV = Get-AzRoleDefinition -Scope '/providers/Microsoft.Management/managementGroups/acfroot-dev'
  $roleDefinitions_PROD = Get-AzRoleDefinition -Scope '/providers/Microsoft.Management/managementGroups/acfroot-prod'
  
  @{
    PROD = $roleDefinitions_PROD
    DEV  = $roleDefinitions_DEV 
  } | ConvertTo-Json -Depth 8 | Out-File -Path "$env:SECRET_STORE/ROLE_DEFINITONS.json"
  $env:ROLE_DEFINITIONS = (Resolve-Path "$env:SECRET_STORE/ROLE_DEFINITONS.json")
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


Import-Module "$PSScriptRoot\Helper"

. $env:PROFILE_HELPERS_PATH/_Utils.ps1
. $env:PROFILE_HELPERS_PATH/_ValidateSets.ps1
. $env:PROFILE_HELPERS_PATH/_SecretStore.ps1

. $env:PROFILE_HELPERS_PATH/VersionControl.ps1
. $env:PROFILE_HELPERS_PATH/Github.ps1
. $env:PROFILE_HELPERS_PATH/Terraform.ps1
. $env:PROFILE_HELPERS_PATH/DevOps.ps1
 

## Initial Script
Write-Host
Get-SecretsFromStore PERSONAL
Get-SecretsFromStore -Show

Add-EnvPaths

#Start-Sleep -Milliseconds 250

$null = Switch-Terraform
Switch-Terraform -TFVersion $env:TF_VERSION_ACTIVE
Set-Item -Path env:TF_DATA_DIR -Value 'C:\TFCACHE'
Switch-GitConfig -config ($env:USERNAME -eq 'M01947' ? 'brz' : 'git')


Write-Host ''
Write-Host '  🤓 Joke of the Session 🤓'
Write-Host "  🎉 $(Get-DumbJoke)"
Write-Host '  👾 !!! Go Go Programming !!! 👾'
Write-Host ''