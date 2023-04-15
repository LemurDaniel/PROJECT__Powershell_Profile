<#
    .SYNOPSIS
    Creates a new Github repository.

    .DESCRIPTION
     Creates a new Github repository.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .EXAMPLE

    Create a repository in the current Context:

    PS> $Repository = @{
        name        = "RepositoryName"
        description = "A description"
        Visibility  = 'private'
        openBrowser = $true
    }

    PS> New-GithubRepository @Repository

    .LINK
        
#>

function New-GithubRepository {

    [CmdletBinding()]
    param (
        # The Name of the Github Repository.
        [Parameter(
            Mandatory = $false,
            Position = 0
        )]
        [System.String]
        $Name,

        # The Name of the Github Context to use. Defaults to current Context.
        [Parameter(
            Mandatory = $false,
            Position = 1
        )]
        [ValidateScript(
            { 
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-GithubContexts).login
            },
            ErrorMessage = 'Please specify an correct Context.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-GithubContexts).login

                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Context,

        # Description for the repository
        [Parameter()]
        [System.String]
        $Description = '',

        # Visibility of the repository
        [Parameter()]
        [validateSet('public', 'private')]
        [System.String]
        $Visibility = 'private',

        # Flag to open the repository in the Browser
        [Parameter()]
        [switch]
        $openBrowser,

        # Flag to not download and open the repository.
        [Parameter()]
        [switch]
        $onlyCreate
    )

    $contextInfo = Get-GithubContextInfo -Context $Context
    
    $Request = @{
        Method  = 'POST'
        Context = $contextInfo.login
        API     = $contextInfo.IsUserContext ? '/user/repos' : '/orgs/{org}/repos'
        Body    = @{
            org         = $contextInfo.login
            name        = $Name
            description = $Description
            private     = $Visibility -eq 'private'
        }
    }

    $repository = Invoke-GithubRest @Request

    if ($Browser) {
        Start-Process $repository.html_url
    }

    # Fetch newly created repo to cache.
    $null = Get-GithubRepositories -Context $contextInfo.login -Refresh
    
    if (!$onlyCreate) {
        Open-GithubRepository -Name $Name -Context $contextInfo.login
    }
    
    return $repository
}