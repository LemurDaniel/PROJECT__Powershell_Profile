
$ErrorActionPreference = "Stop"

## ENV Variables
$env:SECRET_TOKEN_STORE = Join-Path -Path $env:APPDATA -ChildPath "SECRET_TOKEN_STORE/TOKEN_STORE.json"

$env:PS_PROFILE = $PROFILE
$env:PS_PROFILE_PATH = (Resolve-Path "$env:PS_PROFILE\..").Path
$env:PROFILE_HELPERS_PATH = (Resolve-Path "$env:PS_PROFILE\..\Helper").Path


## Resolve Repository Path
$env:RepoPath = "$env:Userprofile/Repos"
$env:RepoPathSecondary = "$env:Userprofile/Documents/Repos"
if (Test-Path $env:RepoPath) {
  $env:RepoPath = (Resolve-Path $env:RepoPath).Path
}
else {
  $env:RepoPath = (Resolve-Path $env:RepoPathSecondary).Path
}

## Resolve App Path
$env:AppPath = "$env:OneDrive/Apps/"
$env:AppPathSecondary = "$env:OneDrive/Dokumente/Apps/"
if (Test-Path $env:AppPath) {
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


$sharingUrl = "https://1drv.ms/u/s!AhqeJjANxATfiu5EcpG9ZpVbLGea1g?e=SS4i85" ##"https://1drv.ms/u/s!AhqeJjANxATfiu5BbYTavFCUtfLXvg?e=3bdKNt";
$byteArray = ([System.Text.Encoding]::UTF8).GetBytes($sharingURL)
$base64Value = [System.Convert]::ToBase64String($byteArray)
$encodedUrl = "u!" + $base64Value.TrimEnd('=').Replace('/', '_').Replace('+', '-');

$URL = "https://api.onedrive.com/v1.0/me/drives"  "shares/$encodedUrl"

Invoke-RestMethod -Method GET -Uri $URL -ContentType "application/json"



$Headers = @{
  Authorization = $env:ONEDRIVE_PERSONAL_BEARER_TOKEN
  "content-type" = "application/json"
}

Invoke-RestMethod -Method GET -Uri $URL -Headers $Headers -Authentication $env:ONEDRIVE_PERSONAL_BEARER_TOKEN

Invoke-RestMethod -Method GET -Uri $URL -Headers $Headers

$secure = ConvertTo-SecureString -String $env:ONEDRIVE_PERSONAL_BEARER_TOKEN -AsPlainText


EwBIA61DBAAUorz77FfV/edREmvlTq6cECb8X/8AAUY%2b8udnDaL%2bsJFSZIp%2bQ/5I1x2wDcBKV3KBlBt/E/Da5TjUhprfvqIs1tgkos9gJ808Vf/ed1qHxzsIoo9Ydpox28yXOucqpg/spVns1NCTbt7HSbHziRM%2bMyvSUy%2bZEY6oqLZAyn83QsRZ4Z1xg1kZ8rUFb%2b5k0rKCmBV06GcEgKFFv4LxZ8rf7QkbQGIzJoW8RqjF3bNMYthIcZd0oEVyhCWHrhdxlLCGs6BKvZqc0KSkC0qJV/YX8ecMU/QmmQfxYmZkJltcD/ln7oDefve/okAliMGeraI/3WieJjGlxW9QisGVoLG0VIGkHm0jVS7%2bJNI03VXq5A11OxKwpiQDZgAACPldjIl53/vVGAICv3wAkA6fngKtF7Xiw40vthr1qiw0JQ8L8aJrzF58L/qHppzDyQfmcZk%2bWS48ZGbUe4%2bpcoWRvJLI7qPExVMiE2G1mrLhYp/5PN9Jfl2FOXZTYcE6ivFHRbj/yo0ztdCovFuAboqCL4PR%2bTEWEI3F8nieKLMwyUyvXgZEJxp3yb941TdOUR/PQPJZ3/Pmi4HGsfBwOfNMttm2FMankLdK7pWBHHO7h4lmfykg1A400INhzCFTc1SzDcP7xXyL%2bHVlElDjWYQmrS1EY0jusKWLQqYjZA2FFMCQQkHCbTAqo3AoeTfIyQp0WXgqfylWf/v5anCQxzlFFVEYvhuiIZvXvYvUKG1JdB%2b7ky4Z%2bzxcetQtJ8GVzVOt3UZW2p6CkSPd0qOmN0g2Bf3gdjhL/wJL5A/J/bALtcHV7ZXyNjWKuv4he5YvX65nyrAP2Th%2bj0oQ6uq8ToUKQRRwuILZRZut5z41RC9D9/5B60CF5UXqCZkvbTSydquwfvok4Ba9PwvSA56A26f9UOsmwNtjSamVE1WFNPSChSFItPmOlXh8PpRwjNERd7raRYzbeb7bispA90md9VSCPUXpNsMMr/oN51TbrnZML/MnikIsZ4aw3lEl/bW/mSZFoMOi4VWPHeYzTXWEGbi3LhnXEbuaaVjQMeaBCNlOETIN3dR%2bBv8rY1KsM8iNu5ZUB0iTv60Yoo0nW%2bf9mQIqTE8C