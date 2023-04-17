

<#
    .SYNOPSIS
    Generate a DallE Image from a Joke and Opens it.

    .DESCRIPTION
    Generate a DallE Image from a Joke and Opens it.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS
    None

    .LINK
        
#>

function Get-DallEFromJoke {

    [CmdletBinding()]
    param ()

    $joke = (Invoke-RestMethod -Method GET -Uri 'https://icanhazdadjoke.com/' -Headers @{'Accept' = 'application/json' }).joke
    
    Write-Host $joke
    $null = Invoke-OpenAIImageGeneration -Prompt $joke -openImage

}