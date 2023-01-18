#Requires -Modules @{ ModuleName="OneDrive"; ModuleVersion="2.2.0" }

Get-ChildItem $PSScriptRoot -Filter '*.ps1' -ErrorAction Stop | ForEach-Object {
    . $_.FullName
}