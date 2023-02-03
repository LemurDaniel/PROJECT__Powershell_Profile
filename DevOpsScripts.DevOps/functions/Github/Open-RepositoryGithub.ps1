function Open-RepositoryGithub {

    [Alias('vcp')]
    [cmdletbinding(
        SupportsShouldProcess,
        ConfirmImpact = 'high'
    )]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [ValidateScript(
            { 
                $_ -in (Get-GithubData 'repositories.name')
            },
            ErrorMessage = 'Please specify an correct Name.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = Get-GithubData 'repositories.name' 

                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Name,

        [Parameter()]
        [switch]
        $noCode,

        # Optional to replace an existing repository at the location and redownload it.
        [Parameter()]
        [switch]
        $replace
    )


    $repository = Get-GithubData 'repositories' | Where-Object -Property Name -EQ -Value $Name
    $repositoryPath = $repository.LocalPath

    if ($replace) {
        if ($PSCmdlet.ShouldProcess($repository.LocalPath, 'Do you want to replace the existing repository and any data in it.')) {
            Remove-Item -Path $repository.LocalPath -Recurse -Force -Confirm:$false
        }
    }

    if (!(Test-Path -Path $repository.LocalPath)) {
        $repository.LocalPath = New-Item -ItemType Directory -Path $repository.LocalPath
        git -C $repository.LocalPath clone $repository.clone_url .
    }
    
    $user = Get-GitUser
    $null = git config --global --add safe.directory ($repository.LocalPath -replace '[\\]+', '/' )
    $null = git -C $repository.LocalPath config --local user.name $user.login 
    $null = git -C $repository.LocalPath config --local user.email $user.email

    if (!$noCode) {
        code $repository.LocalPath
    }

    return Get-Item $repository.LocalPath
}