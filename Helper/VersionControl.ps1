

function Open-RepositoryVSCodeDevOps {
    [Alias("VCD")]
    param (
        [Parameter()]
        [System.Collections.ArrayList]
        $RepositoryName,

        [Parameter()]
        [ValidateSet("DC", "RD")] # DC-Migration, RD-Redeployment
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
        [ValidateSet([RepoProjects])]  # DC-Migration, RD-Redeployment
        $Project = "DC",

        [Parameter()]
        [ValidateSet("local", "devops")]
        $Method = "local"
    )

    $ReposLocation = Get-ChildItem -Path $env:RepoPath -Directory | `
        Where-Object { $_.Name -like "_$Project*" } 

    $Repos = Get-ChildItem -Path $ReposLocation.FullName -Directory | `
        Where-Object { (Get-ChildItem -Path $_.FullName -Hidden -Filter '.git') } 

    if ($Repos) {
        $ChosenRepo = Get-PreferencedObject -SearchObjects $Repos -SearchTags $RepositoryName
    } else {
        return
    }

    if ($ChosenRepo -AND $Method -eq "local") {
        code $ChosenRepo.FullName
        git -C "$($ChosenRepo.FullName)" config --local user.email "$env:GitMailWork"
        git -C "$($ChosenRepo.FullName)" config --local user.name "$env:GitNameWork" 
    }
    else {

        $response = Invoke-AzDevOpsRest -Method GET -Property "value" -API_Project "_apis/git/repositories?api-version=7.1-preview.1" -Project $Project
        $preferedObject = Get-PreferencedObject -SearchObjects $response -SearchTags $RepositoryName
        if ($preferedObject) {
            $preferedObject
            git clone $preferedObject.remoteUrl (Join-Path -Path $ReposLocation -ChildPath $preferedObject.name)
            Open-RepositoryVSCode -RepositoryName $RepositoryName
        }

    }
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
