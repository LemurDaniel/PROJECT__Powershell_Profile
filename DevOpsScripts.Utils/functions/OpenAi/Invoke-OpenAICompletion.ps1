
<#
    .SYNOPSIS
    Invokes the Text-Completion API of open AI with a Model to choose from.

    .DESCRIPTION
    Invokes the Text-Completion API of open AI with a Model to choose from.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS
    Returns the Text-Completion Response.


    .LINK
        
#>

function Invoke-OpenAICompletion {

    [CmdletBinding()]
    param (
        # The Prompt to send to Open AI.
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ValueFromRemainingArguments = $true
        )]
        [System.String]    
        $Prompt,

        # Change the Open AI Text Completion Model. 
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [ValidateSet(
            'text-davinci-003' # Converts Moods to Colors.
        )]
        [System.String]
        $Model,

        # The Open AI parameters
        [Parameter()]
        [System.int32]    
        $n = 1,

        # The Open AI parameters for text completion.
        [Parameter()]
        [System.int32]    
        $temperature = 0,

        # The Open AI parameters
        [Parameter()]
        [System.int32]    
        $max_tokens = 64,

        # The Open AI parameters
        [Parameter()]
        [System.Single]    
        $top_p = 1.0,

        # The Open AI parameters
        [Parameter()]
        [System.Single]    
        $frequency_penalty = 1.0,

        # The Open AI parameters
        [Parameter()]
        [System.Single]    
        $presence_penalty = 1.0,
       
        # The Open AI parameters
        [Parameter()]
        [System.String[]]    
        $stop = @(';')
    )

    $Request = @{
        Method  = 'POST'
        Uri     = 'https://api.openai.com/v1/completions'
        headers = @{
            'Authorization' = "Bearer $ENV:OPEN_AI_API_KEY"
            'Content-Type'  = 'application/json'
        }
        body    = @{
            model       = $Model
            prompt      = $Prompt
            max_tokens  = $max_tokens
            temperature = $temperature
            top_p       = $top_p
            n           = $n
            stream      = $false
            logprobs    = $null
            echo        = $false
            stop        = $stop
        } | ConvertTo-Json -Compress
    }

    return Invoke-RestMethod @Request 
}
