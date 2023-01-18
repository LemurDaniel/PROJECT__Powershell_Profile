

Get-ChildItem $PSScriptRoot -Filter '*.ps1' -ErrorAction Stop | ForEach-Object {
    . $_.FullName
}