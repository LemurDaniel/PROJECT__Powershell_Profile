$ErrorActionPreference = "Stop"

#Hardlinks
<#
try{

  $settings_WindowsTerminal = "C:\Users\Daniel\OneDrive\Dokumente\_Apps\_Settings\WindowsTerminal\settings.json"
  if(Test-Path -Path "$settings_WindowsTerminal") {

    $folder_WindowsTerminal = Get-ChildItem -Directory -Filter "Microsoft.WindowsTerminal*" -Path "C:\Users\Daniel\AppData\Local\Packages\" 
    $file = Get-ChildItem -Path "$($folder_WindowsTerminal.FullName)\LocalState\settings.json"

    if($file.LinkType -ne "Hardlink") {
      Write-Host "Create Hardlink for Terminal-App"
      Remove-Item -Path $file.FullName -Verbose
      $test = New-Item -ItemType HardLink `
        -Path "$($file.Fullname)" `
        -Target "$settings_WindowsTerminal" `
        -Verbose
    }
    #Get-Item -ItemType HardLink -Path $file.FullName -Verbose
  }

} 
catch {
  $_
}
#>

# Config ENVS
$env:QUIET = $true
$env:GitMailWork = "daniel.landau@brz.eu"
$env:GitNameWork = "Daniel Landau"


$env:PS_PROFILE = $PROFILE
$env:PS_PROFILE_PATH = (Resolve-Path "$env:PS_PROFILE\..").Path
$env:PROFILE_HELPERS_PATH = (Resolve-Path "$env:PS_PROFILE_PATH\Helper").Path
#$env:PSModulePath = "$env:PS_PROFILE_PATH\Modules;$PSHOME\Modules;"
#[Environment]::SetEnvironmentVariable("PSModulePath", $env:PSModulePath)

## Same entry also exists in ONEDRIVE/Powershell/7/profile.ps1
## Resolve App Path
$env:OneDrive = $env:OneDriveConsumer ?? $env:OneDrive
$env:AppPath = "$env:OneDrive/_Apps/"
$env:AppPathSecondary = "$env:OneDrive/Dokumente/_Apps/"
if (!(Test-Path $env:AppPath)) {
  $env:AppPath = (Resolve-Path $env:AppPathSecondary).Path
}


## Resolve Repository Path
$env:RepoPath = "$env:Userprofile/Repos"
$env:RepoPathSecondary = "$env:OneDrive/Dokumente/Repos" #"$env:Userprofile/Documents/Repos"
if (!(Test-Path $env:RepoPath)) {
  $env:RepoPath = (Resolve-Path $env:RepoPathSecondary).Path
}

## ENV Variables
$env:SECRET_TOKEN_STORE = "$env:AppPath/_SECRET_STORE/TOKEN_STORE.json"
$env:Secondary_SECRET_TOKEN_STORE = "$env:APPDATA/_SECRET_TOKEN_STORE/TOKEN_STORE.json"
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


<#
# CREDITS: Tim Krehan (tim.krehand@brz.eu)
#>
function Get-DumbJoke {

  param()

  return (Invoke-RestMethod -Method GET -Uri "https://icanhazdadjoke.com/" -Headers @{"Accept" = "application/json"}).joke

}



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
Load-PersonalSecrets -Show
Update-AzDevOpsSecrets
# Get-DevOpsProjects # Takes long

Add-EnvPaths

sleep -Milliseconds 100

Get-TerraformNewestVersion
Switch-Terraform

Set-Item -Path env:TF_DATA_DIR -Value "C:\TFCACHE"

if ($env:USERNAME -eq "M01947") {
  Switch-GitConfig -config brz
}
else {
  Switch-GitConfig -config git
}


Write-Host ""
Write-Host "  🤓 Joke of the Session 🤓"
Write-Host "  🎉 $(Get-DumbJoke)"
Write-Host "  👾 !!! Go Go Programming !!! 👾"
Write-Host ""






function Get-ScrambledText {

  param(
      [Parameter()]
      [System.String]
      $text = (Get-Clipboard)
  )

  $newText = [System.Collections.ArrayList]::new()

  foreach ($word in ($text -split " ")) {
      $word = $word.trim()

      $startLetter = ($word -split "")[1]
      $endLetter = ($word -split "")[-2]

      if ($word.length -le 3) {
          $null = $newText.Add($word)
      }
      else {
          $letters = ($word -split "")[2..($word.length - 1)]
      
          $count = Get-Random -Minimum 2 -Maximum 5
          for ($i = 0; $i -lt $count; $i++) {
              $rand = Get-Random -Minimum 0 -Maximum ($letters.Length - 1)
              $rand2 = Get-Random -Minimum 0 -Maximum ($letters.Length - 1)
              $temp = $letters[$rand]
              $letters[$rand] = $letters[$rand2]
              $letters[$rand2] = $temp
          }

          $letters = $letters -join ""

          $null = $newText.Add("$startLetter" + "$letters" + "$endLetter")
      }
  }

  Set-Clipboard -Value ($newText -join " ")
  return ($newText -join " ")

}