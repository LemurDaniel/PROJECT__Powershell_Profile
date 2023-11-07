

function Add-ConsoleTestImages {

    param (
        # Name of the Entry.
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $Name,
        
        # Path to the file.
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $FilePath
    )

    $Image = Get-Item -Path $FilePath
    if ($Image.Extension -notin @('.png', '.jpg', '.jpeg', '.bmp')) {
        throw [System.InvalidOperationException]::new("Not a valid image type.")
    }

    $Bytes = [System.IO.File]::ReadAllBytes($Image.FullName)
    $Base64 = [System.Convert]::ToBase64String($Bytes)


    $ImageJSONPath = "$PSScriptRoot/../.resources/console.testimages.json" 
    $ImageJSON = Get-Content -Path $ImageJSONPath | ConvertFrom-Json -AsHashtable
    $ImageJSON[$Name] = $Base64

    $ImageJSON 
    | ConvertTo-Json 
    | Out-File -FilePath $ImageJSONPath

}