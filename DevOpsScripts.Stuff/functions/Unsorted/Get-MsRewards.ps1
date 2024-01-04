function Get-MsRewards {

    param (
        [Parameter(Mandatory = $true)]
        [System.Int32]
        $calls,

        [Parameter()]
        [ValidateSet('Edge', 'Opera', 'OperaGX', 'Chrome')]
        $browser = 'Opera'
    )

    $words = Get-Content -Path "C:\Users\Daniel\git\repos\GITHUB\LemurDaniel\LemurDaniel\PROJECT__Powershell_Profile\DevOpsScripts.Stuff\functions\Unsorted\41.284_words.txt"
    # $words = Get-Content -Path "$PSScriptRoot\41.284_words.txt"
    

    # Default Installation paths for browsers on windows.
    $applicationPaths = @{
        Edge    = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
        OperaGX = "C:\Users\$env:USERNAME\AppData\Local\Programs\Opera GX\launcher.exe"
        Opera   = "C:\Users\$env:USERNAME\AppData\Local\Programs\Opera\launcher.exe"
        Chrome  = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
    }
    $baseUrl = 'https://www.bing.com/search?q={0}&form=QBLH'

    $progressBar = @{
        Id       = [DateTime]::Now.Minute
        Activity = 'Bing Search'
        Status   = "0/$Calls"
    }

    for ($current = 0; $current -lt $calls; $current++) {

        $percentComplete = [System.Math]::Floor($current / $calls * 100)
        Write-Progress @progressBar -PercentComplete $percentComplete -Status "$($current+1)/$calls"
        Start-Sleep -Milliseconds (Get-Random -Minimum 10000 -Maximum 12000)
        $word = $words[(Get-Random -Minimum 0 -Maximum $words.Length)]
        $url = [System.String]::Format($baseUrl, $word)
        $null = [system.Diagnostics.Process]::Start($applicationPaths[$browser], $url)
        
    }

    Write-Progress @progressBar -Completed

}