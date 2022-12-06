

function Get-RepositoryVSCode {

    [Alias('VC')]
    param (
        [Parameter()]
        [System.String[]]
        $RepositoryName,

        [Parameter()]
        [alias('not')]
        [System.String[]]
        $excludeSearchTags,

        [Parameter()]
        [ValidateSet([RepoProjects])]  # DC-Migration, RD-Redeployment
        $Project = [RepoProjects]::GetDefaultProject(),

        [Parameter()]
        [ValidateSet('local', 'devops')]
        $Method = 'local',

        [Parameter()]
        [switch]
        $noOpenVSCode,

        [Parameter()]
        [PSCustomObject]
        $RepositoryId
    )

    $ChosenRepo
    if ($RepositoryId) {
        $ChosenRepo = [RepoProjects]::GetRepository($RepositoryId)
    }
    else {
        $Repositories = [RepoProjects]::GetRepositories($Project)
        $ChosenRepo = Search-PreferencedObject -SearchObjects $Repositories -SearchTags $RepositoryName -ExcludeSearchTags $excludeSearchTags
        if (!$ChosenRepo) {
            Write-Host -Foreground RED 'No Repository Found'
            return;
        }
    }

    $repositoryPath = [RepoProjects]::GetRepositoryPath($ChosenRepo.id)

    if (($repositoryPath | Get-ChildItem -Hidden | Measure-Object).Count -eq 0) {
        git -C $repositoryPath.FullName clone $ChosenRepo.remoteUrl .
        git config --global --add safe.directory $repositoryPath.FullName
        git -C "$($repositoryPath.FullName)" config --local user.name "$env:ORG_GIT_USER" 
        git -C "$($repositoryPath.FullName)" config --local user.email "$env:ORG_GIT_MAIL"
    }

    if (-not $noOpenVSCode) {
        code $repositoryPath.FullName
        git -C "$($repositoryPath.FullName)" config --local user.name "$env:ORG_GIT_USER" 
        git -C "$($repositoryPath.FullName)" config --local user.email "$env:ORG_GIT_MAIL"
    }

    return $repositoryPath

}

function Switch-GitConfig {

    [Alias('sc')]
    param(
        [Parameter()]
        [ValidateSet('brz', 'git')]
        $config = 'git'
    )

    if ($config -eq 'brz') {
        $null = git config --global user.name $env:ORG_GIT_USER   
        $null = git config --global user.email $env:ORG_GIT_MAIL
    }
    elseif ($config -eq 'git') {
        $null = git config --global user.name $env:GIT_USER
        $null = git config --global user.email $env:GIT_MAIL
    }

    Write-Host 'Current Global Git Profile:'
    Write-Host "    $(git config --global user.name )"
    Write-Host "    $(git config --global user.email )"
    Write-Host ''

    git -C . rev-parse >nul 2>&1; 
    if ($?) {

        $localMail = git config --local user.email
        $localUser = git config --local user.name

        if ($localMail -AND $LocalUser) {
        
            Write-Host 'Current Local Git Profile:'
            Write-Host "    $localUser"
            Write-Host "    $localMail"
            Write-Host ''
        
        }

    }


}

function Push-Profile {

    $fileItem = Get-RepositoryVSCodePrivate -RepositoryName 'PROJECT__Powershell_Profile' -noCode

    if ($fileItem) {
        $byteArray = [System.BitConverter]::GetBytes((Get-Random))
        $hex = [System.Convert]::ToHexString($byteArray)

        git -C $fileItem.FullName pull origin
        git -C $fileItem.FullName add -A
        git -C $fileItem.FullName commit -m "$hex"
        git -C $fileItem.FullName push
    
    }
        
    $byteArray = [System.BitConverter]::GetBytes((Get-Random))
    $hex = [System.Convert]::ToHexString($byteArray)

    git -C $env:PS_PROFILE_PATH pull origin
    git -C $env:PS_PROFILE_PATH add -A
    git -C $env:PS_PROFILE_PATH commit -m "$hex"
    git -C $env:PS_PROFILE_PATH push

}

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

    $PrivateRepos = Get-SecretFromStore CACHE/GITHUB.repositories PERSONAL
    $preferencedRepository = Search-PreferencedObject -SearchObjects $PrivateRepos -SearchTags $RepositoryName -ExcludeSearchTags $excludeSearchTags

    if (!$preferencedRepository) {
        Write-Host -Foreground RED 'No Repository Found'
        return;
    }

    $repositoryPath = "$env:GIT_REPO_PATH\$($preferencedRepository.login)\$($preferencedRepository.name)"
    if (!(Test-Path -Path $repositoryPath)) {
        $repositoryPath = New-Item -ItemType Directory -Path $repositoryPath
        git -C $repositoryPath.FullName clone $preferencedRepository.clone_url .
        git config --global --add safe.directory $repositoryPath.FullName
        git -C "$($repositoryPath.FullName)" config --local user.name "$env:GIT_USER" 
        git -C "$($repositoryPath.FullName)" config --local user.email "$env:GIT_MAIL"
    }
    else {
        $repositoryPath = Get-Item -Path $repositoryPath
    }

    if (!$noCode) {
        code $repositoryPath.FullName
    }

    return $repositoryPath
}