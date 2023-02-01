
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

    [Alias('openAiImage')]
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

        # Switch to open the Folder defined by outpath
        [Parameter()]
        [Switch]
        $openFolder,

        # The path were to store the generated images.
        [Parameter()]
        [System.String]    
        $OutPath = (Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath 'dallE'),

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
        $n = 1
    )

    $openAIAuth = Get-OpenAIAPIAuthentication
    $Request = @{
        Method  = 'POST'
        Uri     = 'https://api.openai.com/v1/images/generations'
        headers = @{
            'OpenAI-Organization' = $openAIAuth.OpenAIapiOrgId
            'Authorization'       = "Bearer $($openAIAuth.OpenAIapiKey)"
            'Content-Type'        = 'application/json'
        }
        body    = @{
            size            = $ImageSize 
            response_format = 'b64_json'
            prompt          = $Prompt
            n               = $n
        } | ConvertTo-Json -Compress
    }


    if (!(Test-Path -Path $OutPath)) {
        $null = New-Item -ItemType Directory -Path $OutPath
    }
    if ($openFolder) {
        [System.Diagnostics.Process]::start('explorer.exe', $OutPath)
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