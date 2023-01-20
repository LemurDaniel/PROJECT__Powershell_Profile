function Open-RepositoryDynamic {

    [Alias('VCD')]
    [cmdletbinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [ValidateScript(
            { 
                $_ -in (Get-ProjectInfo 'repositories.name')
            },
            ErrorMessage = 'Please specify an correct Name.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                [array] $validValues = Get-ProjectInfo 'repositories.name' | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ }
                $validValues -like "$wordToComplete*"
            }
        )]
        [System.String]
        $Name,

        [Parameter()]
        [switch]
        $onlyDownload,

        [Parameter()]
        [PSCustomObject]
        $RepositoryId
    )


    $repositories = Get-ProjectInfo 'repositories'
    if ($RepositoryId) {
        $repository = $repositories | Where-Object -Property id -EQ -Value $RepositoryId
    }
    else {
        $repository = $repositories | Where-Object -Property name -EQ -Value $Name
    }

    if (!$repository) {
        Write-Host -Foreground RED 'No Repository Found!'
        return
    }
 

    #$adUser = Get-AzADUser -Mail (Get-AzContext).Account.Id # Takes long initialy
    #$userName = $adUser.DisplayName
    #$userMail = $adUser.UserPrincipalName

    $userName = (Get-AzContext).Account.Id -replace '(@{1}.+)', '' -replace '\.', ' ' -replace '', ''
    $userMail = (Get-AzContext).Account.Id

    $TextInfo = (Get-Culture -Name 'de-DE').TextInfo
    $userName = $TextInfo.ToTitleCase($userName)

    if (!(Test-Path $repository.Localpath)) {
        New-Item -Path $repository.Localpath -ItemType Directory
        git -C $repository.Localpath clone $repository.remoteUrl .
    }      

    $item = Get-Item -Path $repository.Localpath 
    $null = git config --global --add safe.directory ($item.Fullname -replace '[\\]+', '/' )
    $null = git -C $repository.Localpath config --local commit.gpgsign false
    $null = git -C $repository.Localpath config --local user.name "$userName" 
    $null = git -C $repository.Localpath config --local user.email "$userMail"

    if (-not $onlyDownload) {
        code $repository.Localpath
    } 

    return $item


}