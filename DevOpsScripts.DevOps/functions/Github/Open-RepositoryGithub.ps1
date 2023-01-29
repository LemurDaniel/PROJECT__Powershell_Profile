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
    $repositoryPath = "$env:GIT_RepositoryPath\$($repository.login)\$($repository.name)"

    if ($replace) {
        if ($PSCmdlet.ShouldProcess($repositoryPath, 'Do you want to replace the existing repository and any data in it.')) {
            Remove-Item -Path $repositoryPath -Recurse -Force -Confirm:$false
        }
    }

    if (!(Test-Path -Path $repositoryPath)) {
        $repositoryPath = New-Item -ItemType Directory -Path $repositoryPath
        git -C $repositoryPath.FullName clone $repository.clone_url .
    }
    else {
        $repositoryPath = Get-Item $repositoryPath
    }

    $null = git config --global --add safe.directory ($repositoryPath.FullName -replace '[\\]+', '/' )
    $null = git -C $repositoryPath.FullName config --local user.name "$env:GIT_USER" 
    $null = git -C $repositoryPath.FullName config --local user.email "$env:GIT_MAIL"

    if (!$noCode) {
        code $repositoryPath.FullName
    }

    return $repositoryPath
}