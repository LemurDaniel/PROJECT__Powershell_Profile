
function Get-RepositoryVSCodePrivate {

    [Alias('VCP')]
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
        $noCode
    )

    $Cache = Get-UtilsCache -Type Github -Identifier 'data'
    $preferencedRepository = Search-In $Cache.repositories -where 'name' -is $RepositoryName -not $excludeSearchTags
    
    if (!$preferencedRepository) {
        Write-Host -Foreground RED 'No Repository Found'
        return;
    }

    #TODO
    $repositoryPath = "$env:GIT_RepositoryPath\$($preferencedRepository.login)\$($preferencedRepository.name)"

    if (!(Test-Path -Path $repositoryPath)) {
        $repositoryPath = New-Item -ItemType Directory -Path $repositoryPath
        git -C $repositoryPath.FullName clone $preferencedRepository.clone_url .
    }


    $repositoryPath = Get-Item -Path $repositoryPath
    $null = git config --global --add safe.directory ($repositoryPath.Fullname -replace '[\\]+', '/' )
    $null = git -C "$($repositoryPath.FullName)" config --local user.name "$env:GIT_USER" 
    $null = git -C "$($repositoryPath.FullName)" config --local user.email "$env:GIT_MAIL"

    if (!$noCode) {
        code $repositoryPath.FullName
    }

    return $repositoryPath
}