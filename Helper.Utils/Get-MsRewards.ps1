function Get-MsRewards {

    param (
        [Parameter(Mandatory = $true)]
        [System.Int32]
        $calls,

        [Parameter()]
        [ValidateSet('Edge', 'Opera', 'Chrome')]
        $browser = 'Opera'
    )

    $words = Get-Content -Path "$env:PS_PROFILE_PATH\.resources\41.284_words.txt"

    $applicationPaths = @{
        Edge   = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
        Opera  = 'C:\Users\Daniel\AppData\Local\Programs\Opera GX\launcher.exe'
        Chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
    }
    $baseUrl = 'https://www.bing.com/search?q={0}'

    for (; $calls -gt 0; $calls--) {

        Start-Sleep -Milliseconds (Get-Random -Minimum 800 -Maximum 2000)
        # $word = Invoke-RestMethod -Method GET -Uri 'https://random-word-api.herokuapp.com/word'
       
        $word = $words[(Get-Random -Minimum 0 -Maximum $words.Length)]

        $url = [System.String]::Format($baseUrl, $word)
        [system.Diagnostics.Process]::Start($applicationPaths[$browser], $url)
    }

}