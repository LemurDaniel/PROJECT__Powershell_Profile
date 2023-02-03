
<#
    .SYNOPSIS
    From the OpenAI Playground. Calls the 'text-davinci-003' Model, asking for the HEX-Code of a color from a description.

    .DESCRIPTION
    From the OpenAI Playground. Calls the 'text-davinci-003' Model, asking for the HEX-Code of a color from a description.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS
    A Window is opened, presenting the Color.

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

    [Alias('moodToColor')]
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
            echo              = $true
            frequency_penalty = 1.0
            presence_penalty  = 1.0
            stop              = @(';')
        }
    )

    $Prompt = "The CSS code for a color like $($Prompt):`nbackground-color:"
    $textResponse = Invoke-OpenAICompletion -Model 'text-davinci-003' -Prompt $Prompt -n $n @openAIparameters | Get-Property choices.text 
    $HexCode = [regex]::Match($textResponse, '#[a-zA-F0-9]{6}').Value
    
    if ([System.String]::isNullOrEmpty($HexCode)) {
        Throw 'Nothing was returned'
    }

    $window = New-WindowFromXAML -Path "$PSScriptRoot/ui/MoodToColorDialog.xaml" -Bind @{
        'HexDisplay.Background' = $HexCode
        'Prompt.Text' = $textResponse
        'HexText.Content' = $HexCode    
        TestButton = @{
            Width = 0
            Height = 0
            #Visibility = [System.Windows.Visibility]::Hidden
            Add_Click = {
                Write-Host 'Test'
                Write-Host 'Test'
                Write-Host 'Test'
                Write-Host 'Test'
                Write-Host 'Test'
            }          
        }
    }

    Write-Host -ForeGround GREEN 'If no Window appears look at the Taskbar. Window might not be focused.'
    return $window.ShowDialog()
}
