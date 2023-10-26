

function Get-ConsoleTestImages {

    param ()

    return Get-Content -Path (Join-Path -Path $PSScriptRoot -Childpath "console.testimages.json") | ConvertFrom-Json -AsHashtable

}