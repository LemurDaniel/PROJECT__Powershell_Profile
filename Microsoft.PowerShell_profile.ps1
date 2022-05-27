
$ErrorActionPreference = "Stop"

## ENV Variables
$env:SECRET_TOKEN_STORE = Join-Path -Path $env:APPDATA -ChildPath "SECRET_TOKEN_STORE/TOKEN_STORE.json"

$env:PS_PROFILE = $PROFILE
$env:PS_PROFILE_PATH = (Resolve-Path "$env:PS_PROFILE\..").Path
$env:PROFILE_HELPERS_PATH = (Resolve-Path "$env:PS_PROFILE\..\Helper").Path


## Resolve Repository Path
$env:RepoPath = "$env:Userprofile/Documents/Repos"
$env:RepoPathSecondary = "$env:Userprofile/Repos"
if (Test-Path $env:RepoPath) {
  $env:RepoPath = (Resolve-Path $env:RepoPath).Path
}
else {
  $env:RepoPath = (Resolve-Path $env:RepoPathSecondary).Path
}

## Resolve App Path
$env:AppPath = "$env:OneDrive/Dokumente/Apps/"
$env:AppPathSecondary = "$env:OneDrive/Dokumente/Apps/"
if (Test-Path $env:TerraformPath) {
  $env:AppPath = (Resolve-Path $env:AppPath).Path
}
else {
  $env:AppPath = (Resolve-Path $env:AppPathSecondary).Path
}




### Resolve Terraform Path
$env:TerraformDocs = (Resolve-Path "$env:AppPath/terraform-docs/").Path
$env:TerraformPath = (Resolve-Path "$env:AppPath/terraform/").Path
$env:TerraformDownloadSource = "https://releases.hashicorp.com/terraform/"
$env:TerraformNewestVersion = (Get-ChildItem -Path $env:TerraformPath | Sort-Object -Descending)[0].FullName
$env:TerraformDocsNewestVersion = (Get-ChildItem -Path $env:TerraformDocs | Sort-Object -Descending)[0].FullName



########################################################################################################################
########################################################################################################################
########################################################################################################################
$env:VSCodeSettings = (Resolve-Path -Path "$env:appdata/code/user/settings.json").Path
#$VSCodeSettings = (Get-Content -Path $env:VSCodeSettings) | ConvertFrom-Json 
#$VSCodeSettings | Add-Member -MemberType NoteProperty -Name "editor.tabSize" -Value 2
#$VSCodeSettings | Add-Member -MemberType NoteProperty -Name "editor.fontFamily" -Value "Jetbrains Mono, Consolas, \'Courier New\', monospace"
#$VSCodeSettings | Add-Member -MemberType NoteProperty -Name "editor.fontLigatures" -Value true
#$VSCodeSettings | ConvertTo-Json -Depth 4 | Out-File -Path $env:VSCodeSettings 
# $env:TerraformPath = (Resolve-Path  "$env:APPDATA/../Local/Microsoft/WindowsApps/terraform").Path

# Invoke-WebRequest -Method GET -Au -Uri "https://dev.azure.com/baugruppe/_apis/projects?api-version=2.0"

########################################################################################################
########################################################################################################
########################################################################################################

## Load Helper Functions
. $env:PROFILE_HELPERS_PATH/_ValidateSets.ps1
. $env:PROFILE_HELPERS_PATH/Base.ps1
. $env:PROFILE_HELPERS_PATH/VersionControl.ps1
. $env:PROFILE_HELPERS_PATH/Terraform.ps1
. $env:PROFILE_HELPERS_PATH/DevOps.ps1
. $env:PROFILE_HELPERS_PATH/Azure.ps1
. $env:PROFILE_HELPERS_PATH/Prompt.ps1
 
## Initial Script

Add-EnvPaths
Get-TerraformNewestVersion
Switch-Terraform
Switch-GitConfig

#if ((Get-AzContext -ListAvailable).Count -eq 0) {
#    Connect-AzAccount
#}
#if ((az account list --all).Count -lt 2) {
#    az login
#}

