

$ErrorActionPreference = "Stop"

# Config ENVS
$env:QUIET = $false

# Config ENVs

$env:PS_PROFILE = $PROFILE
$env:PS_PROFILE_PATH = (Resolve-Path "$env:PS_PROFILE\..").Path
$env:PROFILE_HELPERS_PATH = (Resolve-Path "$env:PS_PROFILE\..\Helper").Path


## Resolve Repository Path
$env:RepoPath = "$env:Userprofile/Repos"
$env:RepoPathSecondary = "$env:Userprofile/Documents/Repos"
if (!(Test-Path $env:RepoPath)) {
  $env:RepoPath = (Resolve-Path $env:RepoPathSecondary).Path
}

## Resolve App Path
$env:AppPath = "$env:OneDrive/Apps/"
$env:AppPathSecondary = "$env:OneDrive/Dokumente/Apps/"
if (!(Test-Path $env:AppPath)) {
  $env:AppPath = (Resolve-Path $env:AppPathSecondary).Path
}

## ENV Variables
$env:SECRET_TOKEN_STORE = "$env:AppPath/SECRET_STORE/TOKEN_STORE.json"
$env:Secondary_SECRET_TOKEN_STORE = "$env:APPDATA/SECRET_TOKEN_STORE/TOKEN_STORE.json"
if (!(Test-Path $env:SECRET_TOKEN_STORE)) {
  $env:SECRET_TOKEN_STORE = (Resolve-Path $env:Secondary_SECRET_TOKEN_STORE).Path
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

$header = @{
	"Accept" = "application/json"
}
$joke = Invoke-RestMethod -Method GET -Uri "https://icanhazdadjoke.com/" -Headers $header


## Load Helper Functions  Load-PersonalSecrets
. $env:PROFILE_HELPERS_PATH/_ValidateSets.ps1
. $env:PROFILE_HELPERS_PATH/_SecretStore.ps1
. $env:PROFILE_HELPERS_PATH/_OneDrivePersonal

. $env:PROFILE_HELPERS_PATH/Base.ps1
. $env:PROFILE_HELPERS_PATH/VersionControl.ps1
. $env:PROFILE_HELPERS_PATH/Terraform.ps1
. $env:PROFILE_HELPERS_PATH/DevOps.ps1
. $env:PROFILE_HELPERS_PATH/Azure.ps1
. $env:PROFILE_HELPERS_PATH/Prompt.ps1
 
Load-PersonalSecrets -Quiet $false

## Initial Script
Update-AzDevOpsSecrets

Add-EnvPaths

Get-TerraformNewestVersion
Switch-Terraform

if ($env:USERNAME -eq "M01947") {
  Switch-GitConfig -config brz
}
else {
  Switch-GitConfig -config git
}


Write-Host ""
Write-Host "  🤓 Joke of the Session 🤓"
Write-Host "  🎉 $($joke.joke)"
Write-Host "  👾 !!! Go Go Programming !!! 👾"
Write-Host ""