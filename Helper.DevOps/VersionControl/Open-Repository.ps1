function Open-Repository {

    [Alias('VC', 'Get-RepositoryVSCode')]
    param (
        [Parameter()]
        [System.String[]]
        $RepositoryName,

        [Parameter()]
        [alias('not')]
        [System.String[]]
        $excludeSearchTags,

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
        $repository = Search-In $repositories -where 'name' -is $RepositoryName -not $excludeSearchTags
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
    git config --global --add safe.directory ($item.Fullname -replace '[\\]+','/' )
    git -C $repository.Localpath config --local user.name "$userName" 
    git -C $repository.Localpath config --local user.email "$userMail"

    if (-not $onlyDownload) {
        code $repository.Localpath
    }

    return $item
}