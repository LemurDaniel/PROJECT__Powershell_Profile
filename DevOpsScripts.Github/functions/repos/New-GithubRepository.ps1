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
        # The name of the github account to use. Defaults to current Account.
        [Parameter(
            Position = 3,
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Account' })]
        [System.String]
        [Alias('a')]
        $Account,

        # The Name of the Github Context to use. Defaults to current Context.
        [Parameter(
            Mandatory = $false,
            Position = 2
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Context' })]
        [System.String]
        [Alias('c')]
        $Context,


        # The Name of the Github Repository.
        [Parameter(
            Mandatory = $false,
            Position = 0
        )]
        [System.String]
        $Name,

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
        API     = $contextInfo.IsUserContext ? '/user/repos' : "/orgs/$($contextInfo.login)/repos"
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