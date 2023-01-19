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