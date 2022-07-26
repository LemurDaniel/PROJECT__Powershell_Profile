

function Open-RepositoryVSCodeDevOps {
    [Alias("VCD")]
    param (
        [Parameter()]
        [System.Collections.ArrayList]
        $RepositoryName,

        [Parameter()]
        [ValidateSet([RepoProjects])] # DC-Migration, RD-Redeployment
        $Project = "DC"
    )

    Open-RepositoryVSCode -RepositoryName $RepositoryName -Method devops -Project $Project
}

function Open-RepositoryVSCode {

    [Alias("VC")]
    param (
        [Parameter()]
        [System.String[]]
        $RepositoryName,

        [Parameter()]
        [alias("not")]
        [System.String[]]
        $excludeSearchTags,

        [Parameter()]
        [ValidateSet([RepoProjects])]  # DC-Migration, RD-Redeployment
        $Project = $env:DEVOPS_DEFAULT_PROJECT,

        [Parameter()]
        [ValidateSet("local", "devops")]
        $Method = "local"
    )

    $Repositories = [RepoProjects]::GetRepositories($Project)
    $ChosenRepo = Get-PreferencedObject -SearchObjects $Repositories -SearchTags $RepositoryName -ExcludeSearchTags $excludeSearchTags
    if(!$ChosenRepo) {
        Write-Host -Foreground RED "No Repository Found"
        return;
    }

    $repository = [RepoProjects]::GetRepositoryPath($ChosenRepo.id)

    if(($repository | Get-ChildItem -Hidden | Measure-Object).Count -eq 0) {
        git -C $repository.FullName clone $ChosenRepo.remoteUrl .
        git -C $repository.FullName config --local user.email "$env:GitMailWork"
        git -C $repository.FullName config --local user.name "$env:GitNameWork" 
    }

    code $repository.FullName
    git -C "$($repository.FullName)" config --local user.email "$env:GitMailWork"
    git -C "$($repository.FullName)" config --local user.name "$env:GitNameWork" 

}

function Switch-GitConfig {

    [Alias("sc")]
    param(
        [Parameter()]
        [ValidateSet("brz", "git")]
        $config = "git"
    )

    if ($config -eq "brz") {
        git config --global user.name  $env:GitNameWork
        git config --global user.email $env:GitMailWork    
    }
    elseif ($config -eq "git") {
        git config --global user.name "LemurDaniel"
        git config --global user.email "landau.daniel.1998@gmail.com"  
    }

    Write-Host "Current Global Git Profile:"
    Write-Host "    $(git config  --global user.name )"
    Write-Host "    $(git config  --global user.email )"
    Write-Host ""

    git -C . rev-parse >nul 2>&1; 
    if($?){

        $localMail = git config --local user.email
        $localUser = git config --local user.name

        if($localMail -AND $LocalUser) {
        
            Write-Host "Current Local Git Profile:"
            Write-Host "    $localUser"
            Write-Host "    $localMail"
            Write-Host ""
        
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
