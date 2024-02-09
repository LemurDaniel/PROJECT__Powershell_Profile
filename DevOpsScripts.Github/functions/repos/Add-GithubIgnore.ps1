<#
    .SYNOPSIS
    Adds a .gitignore template from github to a repository

    .DESCRIPTION
    Adds a .gitignore template from github to a repository

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Add a .gitignore to the current repository:

    PS> Add-GithubIgnore <.gitignore_template>


    .EXAMPLE

    Add a .gitignore to another repository:

    PS> Add-GithubIgnore -Repository <autocomplete_repo> <.gitignore_template>


    .EXAMPLE

    Add a .gitignore to another context:

    PS> Add-GithubIgnore -Repository <autocomplete_repo> <.gitignore_template>
    
    PS> Add-GithubIgnore -Context <autocomplete_context> -Repository <autocomplete_repo> <.gitignore_template>

    PS> Add-GithubIgnore -Account <autocompleted_account> -Repository <autocomplete_repo> <.gitignore_template>


    .LINK
        
#>

function Add-GithubIgnore {

    [CmdletBinding()]
    [Alias('git-ignore')]
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

        # The Name of the Github Repository. Defaults to current Repository.
        [Parameter(
            Mandatory = $false,
            Position = 1
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Repository' })]
        [System.String]
        [Alias('r')]
        $Repository,


        [Parameter(
            Position = 0,
            Mandatory = $false
        )] 
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Gitignore' })]
        [System.String]
        [Alias('Name')]
        $Gitignore
    )

    
    $repositoryData = Get-GithubRepositoryInfo -Account $Account -Context $Context -Name $Repository
    $repositoryIdentifier = @{
        Account    = $repositoryData.Account
        Context    = $RepositoryData.Context
        Repository = $repositoryData.Name
    }

    $null = Open-GithubRepository @repositoryIdentifier -onlyDownload

    $ignoreFilePath = Join-Path -Path $repositoryData.LocalPath -ChildPath ".gitignore"
    if ((Test-Path -Path $ignoreFilePath)) {
        Write-Error "A .gitignore already exists in '$($repositoryData.full_name)'"
    }

    Get-GithubIgnoreTemplate -Name Actionscript 
    | Select-Object -ExpandProperty source
    | Out-File -FilePath $ignoreFilePath
    
}