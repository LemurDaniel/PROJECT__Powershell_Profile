<#
    .SYNOPSIS
    Creates a new Git repository.

    .DESCRIPTION
     Creates a new Git repository.

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

    PS> New-GitRepository @Repository

    .LINK
        
#>

function New-GitRepository {

    [CmdletBinding()]
    param (
        # The name of the Git account to use. Defaults to current Account.
        [Parameter(
            Position = 3,
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Account' })]
        [System.String]
        [Alias('a')]
        $Account,

        # The Name of the Git Context to use. Defaults to current Context.
        [Parameter(
            Mandatory = $false,
            Position = 2
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Context' })]
        [System.String]
        [Alias('c')]
        $Context,


        # The Name of the Git Repository.
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

        # Initialize repository with a gitignore template.
        [Parameter(
            Position = 0,
            Mandatory = $false
        )] 
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Gitignore' })]
        [System.String]
        $Gitignore,

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

    $contextInfo = Get-GitContextInfo -Account $Account -Context $Context
    $contextIdentifier = @{
        Account = $contextInfo.Account
        Context = $Context.login
    }
    
    $Request = @{
        Method  = 'POST'
        Context = $contextInfo.login
        API     = $contextInfo.IsUserContext ? '/user/repos' : "/orgs/$($contextInfo.login)/repos"
        Account = $contextInfo.Account
        Body    = @{
            org         = $contextInfo.login
            name        = $Name
            description = $Description
            private     = $Visibility -eq 'private'
        }
    }

    $repository = Invoke-GitRest @Request -Verbose
    # Fetch newly created repo to cache.
    $null = Get-GitContextInfo @contextIdentifier -Refresh

    if (![System.String]::IsNullOrEmpty($Gitignore)) {
        $gitignoreContent = @{
            Repository = $repository.name
            Path       = ".gitignore"
            message    = "initialize .gitignore"
            Branch     = $repository.default_branch
            Content    = (Get-GitIgnoreTemplate -Gitignore $Gitignore).source
        }
        $null = Set-GitContent @gitignoreContent @contextIdentifier -Verbose
    }

    if ($Browser) {
        Start-Process $repository.html_url
    }
    
    if (!$onlyCreate) {
        Open-GitRepository @contextIdentifier -Repository $repository.name
    }
    
    return $repository
}