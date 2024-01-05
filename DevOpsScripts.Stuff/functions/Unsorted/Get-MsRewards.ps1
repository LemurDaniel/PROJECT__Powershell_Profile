function Get-MsRewards {

    param (
        [Parameter(Mandatory = $true)]
        [System.Int32]
        $calls,

        [Parameter()]
        [ValidateSet('Edge', 'Opera', 'OperaGX', 'Chrome')]
        $browser = 'Opera'
    )

    $words = Get-Content -Path "$PSScriptRoot\41.284_words.txt"
    
    # Default Installation paths for browsers on windows.
    $applicationPaths = @{
        Edge    = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
        OperaGX = "C:\Users\$env:USERNAME\AppData\Local\Programs\Opera GX\launcher.exe"
        Opera   = "C:\Users\$env:USERNAME\AppData\Local\Programs\Opera\launcher.exe"
        Chrome  = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
    }

    $baseUrl = 'https://www.bing.com/search?q={0}&form=QBLH'
    $progressBar = @{
        PercentComplete = 0
        Id              = [DateTime]::Now.Minute
        Activity        = 'Bing Search'
        Status          = "0/$Calls"
    }

    for ($current = 0; $current -lt $calls; $current++) {

        
        $word = $words[(Get-Random -Minimum 0 -Maximum $words.Length)]
        $url = [System.String]::Format($baseUrl, $word)
        $null = [system.Diagnostics.Process]::Start($applicationPaths[$browser], $url)

        if ($calls - $current -GT 1) {
            $progressBar.PercentComplete = [System.Math]::Floor($current / $calls * 100)
            $sleepMilliseconds = Get-Random -Minimum 10000 -Maximum 12000
            for ($sleep = 0; $sleep -LT $sleepMilliseconds; $sleep += 100) {
                Start-Sleep -Milliseconds 100

                $secondsLeft = [System.Math]::Floor(($sleepMilliseconds - $sleep) / 1000)
                $milliSecondsLeft = [System.Math]::Floor(($sleepMilliseconds - $sleep) % 1000 / 100)
                $progressBar.Status = "$($current+1)/$calls - (Next in $secondsLeft.$milliSecondsLeft Seconds)"

                Write-Progress @progressBar
            }
        }
        
    }

    Write-Progress @progressBar -Completed

}