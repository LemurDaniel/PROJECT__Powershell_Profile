


Get-ChildItem $PSScriptRoot -Filter '*.ps1' -File -ErrorAction Stop | ForEach-Object {
    . $_.FullName
}