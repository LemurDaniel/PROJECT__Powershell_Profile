<#
    .SYNOPSIS
    Adds a .gitignore template from Git to a repository

    .DESCRIPTION
    Adds a .gitignore template from Git to a repository

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Add a .gitignore to the current repository:

    PS> Add-GitIgnore <.gitignore_template>


    .EXAMPLE

    Add a .gitignore to another repository:

    PS> Add-GitIgnore -Repository <autocomplete_repo> <.gitignore_template>


    .EXAMPLE

    Add a .gitignore to another context:

    PS> Add-GitIgnore -Repository <autocomplete_repo> <.gitignore_template>
    
    PS> Add-GitIgnore -Context <autocomplete_context> -Repository <autocomplete_repo> <.gitignore_template>

    PS> Add-GitIgnore -Account <autocompleted_account> -Repository <autocomplete_repo> <.gitignore_template>


    .LINK
        
#>

function Add-GitIgnore {

    [CmdletBinding()]
    [Alias('git-ignore')]
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

        # The Name of the Git Repository. Defaults to current Repository.
        [Parameter(
            Mandatory = $false,
            Position = 1
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Repository' })]
        [System.String]
        [Alias('r')]
        $Repository,


        [Parameter(
            Position = 0,
            Mandatory = $false
        )] 
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Gitignore' })]
        [System.String]
        [Alias('Name')]
        $Gitignore,


        # Save the template to the clipboard instead.
        [Parameter()]
        [switch]
        $Clipboard
    )

    if ($Clipboard) {
        Get-GitIgnoreTemplate -Name $Gitignore
        | Select-Object -ExpandProperty source 
        | Set-Clipboard
    }

    if ( 
        ( 
            [System.String]::IsNullOrEmpty($Repository) -AND 
            [System.String]::IsNullOrEmpty($Context) -AND 
            [System.String]::IsNullOrEmpty($Account) 
        ) -OR $Clipboard
    ) {
        return Get-GitIgnoreTemplate -Name $Gitignore
        | Select-Object -ExpandProperty source
    }
    
    $repositoryData = Get-GitRepositoryInfo -Account $Account -Context $Context -Name $Repository
    $repositoryIdentifier = @{
        Account    = $repositoryData.Account
        Context    = $repositoryData.Context
        Repository = $repositoryData.Repository
    }

    $null = Open-GitRepository @repositoryIdentifier -onlyDownload

    $ignoreFilePath = Join-Path -Path $repositoryData.LocalPath -ChildPath ".gitignore"
    if ((Test-Path -Path $ignoreFilePath)) {
        Write-Error "A .gitignore already exists in '$($repositoryData.full_name)'"
    }

    Get-GitIgnoreTemplate -Name $Gitignore
    | Select-Object -ExpandProperty source
    | Out-File -FilePath $ignoreFilePath

}