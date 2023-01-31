

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

    Get All repository Ids in a Project:

    PS> Get-ProjectInfo | return 'repositories'


    .LINK
        
#>

function Invoke-DallEImageFromPrompt {

    param (
        # The Prompt to send to DallE.
        [Parameter(
            Position = 0,
            ValueFromRemainingArguments = $true
        )]
        [System.String]    
        $Prompt,

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
        [System.int]    
        $n = 1
    )

    $Request = @{
        Method  = 'POST'
        Uri     = 'https://api.openai.com/v1/images/generations'
        headers = @{
            'Authorization' = "Bearer $ENV:OPEN_AI_API_KEY"
            'Content-Type'  = 'application/json'
        }
        body    = @{
            size            = $ImageSize 
            response_format = 'b64_json'
            prompt          = $Prompt
            n               = $n
        } | ConvertTo-Json -Compress
    }

    $response = Invoke-RestMethod @Request | 
    
    return $response | get data.b64_json | `
        ForEach-Object { $index = 1 } {

        $bytes = [System.Convert]::FromBase64String($_)
        $timeStamp = [System.DateTime]::Now.ToString('yyyy-MM-dd')
        $fileName = "$timestamp - $prompt.$index.jpg"
        $fullPath = Join-Path -Path $OutPath -ChildPath $fileName
        [System.IO.File]::WriteAllBytes($fullPath, $bytes)
        $index++

        return Get-Item $fullPath
    }

}