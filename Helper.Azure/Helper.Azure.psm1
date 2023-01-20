

Write-Host 'Hello'
Write-Host $PSScriptRoot
Write-Host ((Get-ChildItem $PSScriptRoot -Filter '*.ps1' -File).Name)
Get-ChildItem $PSScriptRoot -Filter '*.ps1' -File -ErrorAction Stop | ForEach-Object {
    . $_.FullName
}
Write-Host ((Get-ChildItem $PSScriptRoot -Filter '*.ps1' -File).Name)