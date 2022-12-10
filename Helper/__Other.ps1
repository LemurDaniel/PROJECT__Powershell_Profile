
function Get-ScrambledText {

    param(
        [Parameter()]
        [System.String]
        $text = (Get-Clipboard)
    )

    $newText = [System.Collections.ArrayList]::new()

    foreach ($word in ($text -split ' ')) {
        $word = $word.trim()

        $startLetter = ($word -split '')[1]
        $endLetter = ($word -split '')[-2]

        if ($word.length -le 3) {
            $null = $newText.Add($word)
        }
        else {
            $letters = ($word -split '')[2..($word.length - 1)]
      
            $count = Get-Random -Minimum 2 -Maximum 5
            for ($i = 0; $i -lt $count; $i++) {
                $rand = Get-Random -Minimum 0 -Maximum ($letters.Length - 1)
                $rand2 = Get-Random -Minimum 0 -Maximum ($letters.Length - 1)
                $temp = $letters[$rand]
                $letters[$rand] = $letters[$rand2]
                $letters[$rand2] = $temp
            }

            $letters = $letters -join ''

            $null = $newText.Add("$startLetter" + "$letters" + "$endLetter")
        }
    }

    Set-Clipboard -Value ($newText -join ' ')
    return ($newText -join ' ')

}

function Get-DailyMsRewards {
    param()
 
    Get-MsRewards -calls 21 -browser Chrome
    Get-MsRewards -calls 4 -browser Edge
    Get-MsRewards -calls 30 -browser Opera

}

function Get-MsRewards {

    param (
        [Parameter(Mandatory = $true)]
        [System.Int32]
        $calls,

        [Parameter()]
        [ValidateSet('Edge', 'Opera', 'Chrome')]
        $browser = 'Opera'
    )

    $applicationPaths = @{
        Edge   = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
        Opera  = 'C:\Users\Daniel\AppData\Local\Programs\Opera GX\launcher.exe'
        Chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
    }
    $baseUrl = 'https://www.bing.com/search?q={0}'


    for (; $calls -gt 0; $calls--) {

        Start-Sleep -Milliseconds (Get-Random -Minimum 800 -Maximum 2000)
        $word = Invoke-RestMethod -Method GET -Uri 'https://random-word-api.herokuapp.com/word'
        $url = [System.String]::Format($baseUrl, $word)
        [system.Diagnostics.Process]::Start($applicationPaths[$browser], $url)
    }

}
