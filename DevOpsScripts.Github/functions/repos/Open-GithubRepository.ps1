<#
    .SYNOPSIS
    Downloads and opens a Github-Repository by current Context or specified.

    .DESCRIPTION
    Downloads and opens a Github-Repository by current Context or specified.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Path to the Repository

    .EXAMPLE

    Open a repository in the current Context:

    PS> Open-GithubRepository <autocomplete_repo>

    .EXAMPLE

    Open a repository in another Context:

    PS> Open-GithubRepository -Context <autocomplete_context> <autocomplete_repo>

    .LINK
        
#>

function Open-GithubRepository {

    [Alias('gitvc')]
    [cmdletbinding(
        SupportsShouldProcess,
        ConfirmImpact = 'high'
    )]
    param (
        [Parameter(
            Position = 2,
            Mandatory = $false
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-UtilsCache -Identifier context.accounts.all -AsHashTable).keys
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [validateScript(
            {
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-UtilsCache -Identifier context.accounts.all -AsHashTable).keys
            }
        )]
        $Account,

        # The Name of the Github Repository.
        [Parameter(
            Mandatory = $false,
            Position = 0
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
                $Context = Get-GithubContextInfo -Account $fakeBoundParameters['Account'] -Context $fakeBoundParameters['Context']
                $validValues = $Context.repositories.Name

                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Name,

        # The Name of the Github Context to use. Defaults to current Context.
        [Parameter(
            Mandatory = $false,
            Position = 1
        )]
        #[ValidateScript(
        #    { 
        #        [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-GithubContexts).login
        #    },
        #    ErrorMessage = 'Please specify an correct Context.'
        #)]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
                $validValues = (Get-GithubContexts -Account $fakeBoundParameters['Account']).login

                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Context,

        # Only open the repository in the browser.
        [Parameter()]
        [switch]
        $Browser,

        # Only Download the Repository without opening it.
        [Parameter()]
        [switch]
        $onlyDownload,

        # Optional to replace an existing repository at the location and redownload it.
        [Parameter()]
        [switch]
        $replace
    )

    $repository = Get-GithubRepositoryInfo -Account $Account -Context $Context -Name $Name

    if ($Browser) {
        return Start-Process $repository.html_url
    }

    if ($replace) {
        if ($PSCmdlet.ShouldProcess($repository.LocalPath, 'Do you want to replace the existing repository and any data in it.')) {
            Remove-Item -Path $repository.LocalPath -Recurse -Force -Confirm:$false
        }
    }


    if (!(Test-Path -Path $repository.LocalPath)) {
        $repository.LocalPath = New-Item -ItemType Directory -Path $repository.LocalPath

        if ((Get-GithubAccountContext).useSSH) {
            git -C $repository.LocalPath clone $repository.ssh_url .
        }
        else {
            git -C $repository.LocalPath clone $repository.clone_url .
        }
    }
    
    $safeDirectoyPath = ($repository.LocalPath -replace '[\\]+', '/' )
    $included = (git config --global --get-all safe.directory | Where-Object { $_ -eq $safeDirectoyPath } | Measure-Object).Count -gt 0
    if (!$included) {
        $null = git config --global --add safe.directory $safeDirectoyPath
    }

    $user = Get-GithubUser
    $null = git -C $repository.LocalPath config --local user.name $user.login 
    $null = git -C $repository.LocalPath config --local user.email $user.email

    if (!$onlyDownload) {
        code $repository.LocalPath
    }

    return Get-Item $repository.LocalPath
}