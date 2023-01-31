
<#
    .SYNOPSIS
    From the OpenAI Playground. Calls the 'text-davinci-003' Model, asking for the HEX-Code of a color from a description.

    .DESCRIPTION
    From the OpenAI Playground. Calls the 'text-davinci-003' Model, asking for the HEX-Code of a color from a description.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS
    If switch returnHex is set, will return the Hex-Color, else a Window is opened, presenting the Color.

    .EXAMPLE

    Generate a Hex-Code from the Prompt 'A warm reddish sunset' and open a Dialog:

    Invoke-OpenAIMoodToColor A warm reddish sunset


    .EXAMPLE

    Generate a Hex-Code from the Prompt 'A warm reddish sunset' and return the Hex-Value:

    Invoke-OpenAIMoodToColor -returnHex A warm reddish sunset

    .NOTES

    Testing Open AI, Playground.
    
    .LINK
        
#>

function Invoke-OpenAIMoodToColor {

    [Alias('ColorOpenAI')]
    [CmdletBinding()]
    param (
        # The Prompt to send to Open AI.
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromRemainingArguments = $true
        )]
        [System.String]    
        $Prompt,

        # Switch to return the HEX-Value insted of opening a Window.
        [Parameter()]
        [switch]    
        $returnHex,

        # The Open AI parameters
        [Parameter()]
        [System.int32]    
        $n = 1,

        # The Open AI parameters for text completion.
        [Parameter()]
        [System.Collections.Hashtable]    
        $openAIparameters = @{
            temperature       = 0
            max_tokens        = 64
            top_p             = 1.0
            frequency_penalty = 1.0
            presence_penalty  = 1.0
            stop              = @(';')
        }
    )

    $Prompt = "The CSS code for a color like $($Prompt):`nbackground-color:"
    $Prompt
    $HexCode = Invoke-OpenAICompletion -Model 'text-davinci-003' -Prompt $Prompt -n $n @openAIparameters | `
        Get-Property choices.text | ForEach-Object { [regex]::Match($_, '#[a-zA-F0-9]{6}').Value }

    if ($returnHex) {
        return $HexCode
    }

    # Else
    $window = New-WindowFromXAML -Path "$PSScriptRoot/ui/MoodToColorDialog.xaml"
    $window.FindName('HexDisplay').Background = $HexCode
    $window.FindName('Prompt').Text = $Prompt
    $window.FindName('HexText').Content = $HexCode
    $window.Activate()

    Write-Host -ForeGround GREEN 'Look at the Taskbar. Window might not be focused.'
    $window.ShowDialog()
}
