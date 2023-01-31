
<#
    .SYNOPSIS
    Sends a Prompt to OpenAI ImageGeneration and saves the API-Response as a file.

    .DESCRIPTION
    Sends a Prompt to OpenAI ImageGeneration and saves the API-Response as a file.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS
    Returns the Fileitems of the generated images.


    .EXAMPLE

    Sends the Request to OpenAI, save the images at a temporary path and opens them in Windows-Default for jpg:

    PS> Invoke-OpenAIImageGeneration -OpenImage An otter flying to otter-space.

    .LINK
        
#>

function Invoke-OpenAIImageGeneration {

    [CmdletBinding()]
    param (
        # The Prompt to send to DallE.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromRemainingArguments = $true
        )]
        [System.String]    
        $Prompt,

        # Switch to open the image in the Windows-Default-Foto-View for .jpg
        [Parameter()]
        [Switch]
        $openImage,

        # The path were to store the generated images.
        [Parameter()]
        [System.String]    
        $OutPath = [System.IO.Path]::GetTempPath(),

        # An image size to return from DallE.
        [Parameter()]
        [ValidateSet(
            '256x256',
            '512x512',
            '1024x1024'
        )]
        [System.String]    
        $ImageSize = '512x512',

        # The Number of Images to return.
        [Parameter()]
        [ValidateRange(1, 10)]
        [System.int32]    
        $n = 1,

        # The Open AI token for the Request.
        [Parameter()]
        [System.String]    
        $API_TOKEN
    )

    $API_TOKEN = [System.String]::isNullOrEmpty($API_TOKEN) ? $env:OPEN_AI_API_KEY : $API_TOKEN

    $Request = @{
        Method  = 'POST'
        Uri     = 'https://api.openai.com/v1/images/generations'
        headers = @{
            'Authorization' = "Bearer $API_TOKEN"
            'Content-Type'  = 'application/json'
        }
        body    = @{
            size            = $ImageSize 
            response_format = 'b64_json'
            prompt          = $Prompt
            n               = $n
        } | ConvertTo-Json -Compress
    }

    $invalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
    $regex = [System.String]::Format('[{0}]', [regex]::Escape( $invalidChars))
    $promptFilenameCleaned = [regex]::Replace($prompt, $regex, '_')

    return Invoke-RestMethod @Request | Get-Property data.b64_json | `
        ForEach-Object { $index = 1 } {

        $bytes = [System.Convert]::FromBase64String($_)
        $timeStamp = [System.DateTime]::Now.ToString('yyyy-MM-dd')
        $fileName = "$timestamp - $promptFilenameCleaned.$index.jpg"
        $fullPath = Join-Path -Path $OutPath -ChildPath $fileName
        [System.IO.File]::WriteAllBytes($fullPath, $bytes)
        $index++

        if ($openImage) {
            Start-Process $fullPath
        }
        return Get-Item $fullPath
    }

}