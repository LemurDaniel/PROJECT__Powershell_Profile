## ENV Variables
$env:SECRET_TOKEN_STORE = Join-Path -Path $env:APPDATA -ChildPath "SECRET_TOKEN_STORE/TOKEN_STORE.json"

$env:PS_PROFILE = $PROFILE
$env:PS_PROFILE_PATH = (Resolve-Path "$env:PS_PROFILE\..").Path
$env:PROFILE_HELPERS_PATH = (Resolve-Path "$env:PS_PROFILE\..\Helper").Path

$env:RepoPathPrimary = (Resolve-Path  "$env:Userprofile/Documents/Repos").Path
$env:RepoPathSecondary = (Resolve-Path  "$env:Userprofile/Documents/Repos").Path

$env:TerraformPath = (Resolve-Path "$env:OneDrive/Dokumente/Apps/terraform/").Path
$env:TerraformDownloadSource = "https://releases.hashicorp.com/terraform/"

$env:InitialEnvsPaths = $env:Path
$env:RepoPath = $env:RepoPathPrimary 

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

