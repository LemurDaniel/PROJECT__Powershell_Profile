
<#
    .SYNOPSIS
    Replaces all invisible and other uncodes like En Space U+2002, etc with normal U+0020.

    .DESCRIPTION
    Replaces all invisible and other uncodes like En Space U+2002, etc with normal U+0020.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .EXAMPLE

    Check if current Path is a Repository:

    PS> Test-IsRepository 

    .LINK
        
#>
function Remove-InvisibleUnicode {

    param (
        [Parameter()]
        [System.String]
        $Path = '.',

        [Parameter()]
        [System.String[]]
        $Extensions = @('.ps1', '.json', '.txt', '.md'),

        [Parameter()]
        [switch]
        $Recurse
    )

    $totalRemovedCharacters = 0
    $WhiteSpace = [System.Char]::ConvertFromUtf32('0x0020')
    $Tablutation = [System.Char]::ConvertFromUtf32('0x0009')
    $unicodeReference = Get-Content "$PSScriptRoot/.resources/unicode.invisible.json" 
    | ConvertFrom-Json
    | Where-Object {
        $_.'Character' -NE $WhiteSpace -AND $_.'Character' -NE $Tablutation
    }

    $progressBar = @{
        Id = Get-Random -Max 256
        Activity = 'Remove invisible' 
        Status  = "None"
        PercentComplete = 0
    }

    $basePath = Get-Item -Path $Path
    $items = Get-ChildItem -Path $Path -Recurse:$Recurse
    | Where-Object {
        $_.Extension -in $Extensions
    }
    for($index = 0; $index -lt $items.Count; $index++) {

        $removed = 0
        $file = $items[$index]
        $content = Get-Content -Path $file.FullName -Raw

        if($null -eq $content -OR $content.Length -eq 0) {
            continue
        }
  
        $unicodeReference | ForEach-Object {
            $regexPattern  = $_.'Unicode'.replace('U+','\u')
            $removed += [regex]::Matches($content, $regexPattern).Count
            $content = $content -replace $regexPattern, $WhiteSpace

            if( [regex]::Matches($content, $regexPattern).Count -gt 0){
                Write-Host $regexPattern
            }
        }

        $location = $file.FullName.replace($basePath, '')
        $progressBar.Status = "Total: $totalRemovedCharacters | Removed $removed @$location)"
        $progressBar.PercentComplete = $index / $items.Count * 100
        Write-Progress @progressBar
        if($removed -gt 0) {
            $totalRemovedCharacters += $removed
            $content | Out-File $file.FullName
        }
    }

    Write-Progress @ProgressBar -Completed
    Write-Host "Removed $totalRemovedCharacters @$Path"
}


<#



$listOfInformation = @()
Get-Content .\unicode.invisible.json 
| ConvertFrom-Json 
| ForEach-Object { 
  $html = Invoke-WebRequest -Uri "https://www.compart.com/en/unicode/$_"

  $tableInformation = [regex]::Match($html, '<table class="data-table">[\S,\s]*?</table>')
  $unicodeInformation = @{}

  [regex]::Matches($tableInformation, "<tr>[\S\s]*?</tr>") 
| Select-Object -ExpandProperty Value
| ForEach-Object {
    $elements = [regex]::Matches($_, "<td[\S\s]*?</td>") 
  | ForEach-Object {
      return [regex]::Match($_, '">[\S\s]*?</td>') `
        -replace '<[\S\s]*?>', '' `
        -replace '">', '' `
        -replace '\s+', ' ' `
        -replace '\[\d+\]', '' `
        -replace ':', ''
    }
    $null = $unicodeInformation.Add($elements[0].trim(), $elements[1].trim())
  }
  $listOfInformation += [ordered]@{
    'Character'             = [System.Char]::ConvertFromUtf32($unicodeInformation['UTF-32 Encoding'])
    'Unicode'               = $_
    'Name'                  = $unicodeInformation['Name']
    'Unicode Version'       = $unicodeInformation['Unicode Version']
    'Script'                = $unicodeInformation['Script']
    'Category'              = $unicodeInformation['Category']
    'Plane'                 = $unicodeInformation['Plane']
    'Block'                 = $unicodeInformation['Block']
    'UTF-32 Encoding'       = $unicodeInformation['UTF-32 Encoding']
    'UTF-16 Encoding'       = $unicodeInformation['UTF-16 Encoding']
    'UTF-8 Encoding'        = $unicodeInformation['UTF-8 Encoding']
    'Bidirectional Class'   = $unicodeInformation['Bidirectional Class']
    'Character is Mirrored' = $unicodeInformation['Character is Mirrored']
    'HTML Entity'           = $unicodeInformation['HTML Entity'] -split ' '
  }
}


$listOfInformation 
| ConvertTo-Json
| Out-File .\unicode.invisible.s.json
#>