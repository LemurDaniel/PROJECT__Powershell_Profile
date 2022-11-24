

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
        $ChosenRepo = Get-PreferencedObject -SearchObjects $Repositories -SearchTags $RepositoryName -ExcludeSearchTags $excludeSearchTags
        if (!$ChosenRepo) {
            Write-Host -Foreground RED 'No Repository Found'
            return;
        }
    }

    $repositoryPath = [RepoProjects]::GetRepositoryPath($ChosenRepo.id)

    if (($repositoryPath | Get-ChildItem -Hidden | Measure-Object).Count -eq 0) {
        git -C $repositoryPath.FullName clone $ChosenRepo.remoteUrl .
        git config --global --add safe.directory $repositoryPath.FullName
        git -C $repositoryPath.FullName config --local user.email "$env:GitMailWork"
        git -C $repositoryPath.FullName config --local user.name "$env:GitNameWork" 
    }

    if (-not $noOpenVSCode) {
        code $repositoryPath.FullName
        git -C "$($repositoryPath.FullName)" config --local user.email "$env:GitMailWork"
        git -C "$($repositoryPath.FullName)" config --local user.name "$env:GitNameWork" 
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
        git config --global user.name $env:GitNameWork
        git config --global user.email $env:GitMailWork    
    }
    elseif ($config -eq 'git') {
        git config --global user.name 'LemurDaniel'
        git config --global user.email 'landau.daniel.1998@gmail.com'  
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

    $byteArray = [System.BitConverter]::GetBytes((Get-Random))
    $hex = [System.Convert]::ToHexString($byteArray)
        
    git -C $env:PS_PROFILE_PATH pull origin
    git -C $env:PS_PROFILE_PATH add -A
    git -C $env:PS_PROFILE_PATH commit -m "$hex"
    git -C $env:PS_PROFILE_PATH push

}


function Find-PrivateRepos {

    $PrivateRepos = [System.Collections.ArrayList]::new()
    Get-ChildItem $env:PRIVATE_REPO_PATH -Recurse -Directory -Filter '.git' -Hidden | `
    ForEach-Object {
        $null = $PrivateRepos.Add([PSCustomObject]@{
            Name = $_.Parent.Name
            path = $_.Parent.FullName
        })

        $null = git config --global --add safe.directory $_.Parent.FullName
    }
    Update-SecretStore -SecretType 'GIT_PRIVATE_REPOS' -SecretValue $PrivateRepos -SecretStoreSource 'PERSONAL' -NOLOAD

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
        $excludeSearchTags
    )

    $PrivateRepos = Get-SecretFromStore 'GIT_PRIVATE_REPOS'
    $ChosenRepo = Get-PreferencedObject -SearchObjects $PrivateRepos -SearchTags $RepositoryName -ExcludeSearchTags $excludeSearchTags

    code $ChosenRepo.path
}