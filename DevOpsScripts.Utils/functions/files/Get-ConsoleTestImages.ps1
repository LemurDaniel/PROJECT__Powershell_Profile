

function Get-ConsoleTestImages {

    param ()

    return Get-Content -Path "$PSScriptRoot/../.resources/console.testimages.json" | ConvertFrom-Json -AsHashtable

}