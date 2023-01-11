
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
        [ValidateSet([Project])]
        $Project = [Project]::DEFAULT,

        [Parameter()]
        [ValidateSet('local', 'devops')]
        $Method = 'local',

        [Parameter()]
        [switch]
        $onlyDownload,

        [Parameter()]
        [PSCustomObject]
        $RepositoryId
    )


    $ChosenRepo = $null
    if ($RepositoryId) {
        $ChosenRepo = [Repository]::GetById($RepositoryId)
    }
    else {
        $Repositories = [Repository]::GetByProjectName($Project)
        $ChosenRepo = Search-In $Repositories -where 'name' -is $RepositoryName -not $excludeSearchTags
    }


    if (!$ChosenRepo) {
        Write-Host -Foreground RED 'No Repository Found'
        return;
    }

    $repositoryPath = [Repository]::GetRepositoryPath($ChosenRepo.id)
    if (($repositoryPath | Get-ChildItem -Hidden | Measure-Object).Count -eq 0) {
        git -C $repositoryPath.FullName clone $ChosenRepo.remoteUrl .
        git config --global --add safe.directory $repositoryPath.FullName
        git -C "$($repositoryPath.FullName)" config --local user.name "$env:ORG_GIT_USER" 
        git -C "$($repositoryPath.FullName)" config --local user.email "$env:ORG_GIT_MAIL"
    }

    if (-not $onlyDownload) {
        code $repositoryPath.FullName
        git -C "$($repositoryPath.FullName)" config --local user.name "$env:ORG_GIT_USER" 
        git -C "$($repositoryPath.FullName)" config --local user.email "$env:ORG_GIT_MAIL"
    }

    return $repositoryPath

}

function Import-GPGKeys {

    param()

    $gpgKey1drv = Get-OneDriveElementsAt -Path '/Dokumente/_Apps/_SECRET_STORE/_gpgkeys' | `
        Get-OneDriveItems | ForEach-Object { $null = gpg --import $privKey }
    
    $null = Remove-Item -Path $gpgKey1drv.Directory -Recurse
}

function Switch-GitConfig {

    [Alias('sc')]
    param(
        [Parameter()]
        [ValidateSet('brz', 'git')]
        $config = 'git'
    )

    $null = git config --global gpg.program "$($global:DefaultEnvPaths['gpg'])/gpg.exe"
    $null = git config --global --unset gpg.format
    $null = git config --global user.signingkey $env:GIT_GPG_ID    

    if ($config -eq 'brz') {
        $null = git config --global user.name $env:ORG_GIT_USER   
        $null = git config --global user.email $env:ORG_GIT_MAIL   
      
        $null = git config --global commit.gpgsign false
    }
    elseif ($config -eq 'git') {
        $null = git config --global user.name $env:GIT_USER
        $null = git config --global user.email $env:GIT_MAIL
   
        $null = git config --global commit.gpgsign true
    }

    # Overwrite settings for gpg-agent to set passphrase
    # Then Reload agent and set acutal Passphrase
    $gpgMainFolder = Get-ChildItem $env:APPDATA -Filter 'gnupg'
    "default-cache-ttl 34560000`r`nmax-cache-ttl 34560000`r`nallow-preset-passphrase" | Out-File -FilePath "$($gpgMainFolder.FullName)/gpg-agent.conf"
    $null = gpgconf --kill gpg-agent #gpg-connect-agent reloadagent /bye
    $null = gpgconf --launch gpg-agent
    $null = $env:GIT_GPG_PHRASE | gpg-preset-passphrase -c $env:GIT_GPG_GRIP

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

    param()

    $fileItem = Get-RepositoryVSCodePrivate -RepositoryName 'PROJECT__Powershell_Profile' -noCode

    Switch-GitConfig -config GIT

    if ($fileItem) {
        $byteArray = (1..4 | ForEach-Object { [byte](Get-Random -Max 256) })
        $hex = [System.Convert]::ToHexString($byteArray)

        git -C $fileItem.FullName pull origin
        git -C $fileItem.FullName add -A
        git -C $fileItem.FullName commit -S -m "$hex"
        git -C $fileItem.FullName push
    
    }
        
    $byteArray = (1..4 | ForEach-Object { [byte](Get-Random -Max 256) })
    $hex = [Convert]::ToHexString($byteArray)

    git -C $env:PS_PROFILE_PATH pull origin
    git -C $env:PS_PROFILE_PATH add -A
    git -C $env:PS_PROFILE_PATH commit -S -m "$hex"
    git -C $env:PS_PROFILE_PATH push

    Switch-GitConfig -config ($env:USERNAME -eq 'M01947' ? 'brz' : 'git')
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
    $preferencedRepository = Search-In $PrivateRepos -where 'name' -is $RepositoryName -not $excludeSearchTags
    
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