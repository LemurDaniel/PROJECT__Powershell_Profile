

$env:PS_PROFILE = $PROFILE
$env:PS_PROFILE_PATH = (Resolve-Path "$env:PS_PROFILE\..").Path
$env:PROFILE_HELPERS_PATH = (Resolve-Path "$env:PS_PROFILE_PATH\Helper").Path
. $env:PROFILE_HELPERS_PATH/__Other.ps1

Get-DailyMsRewards