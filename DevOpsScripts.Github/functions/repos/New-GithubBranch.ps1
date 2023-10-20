<#
    .SYNOPSIS
    Get a list of all releases of a repository.

    .DESCRIPTION
    Get a list of all releases of a repository.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


        .EXAMPLE

        Get a list of releases for the repository on the current path:

        PS> Get-GithubReleases


        .EXAMPLE

        Get a list of releases a specific repository in another account:

        PS> Get-GithubReleases -Account <autocompleted_account> <autocomplete_repo>


        .EXAMPLE

        Get a list of releases in another Account and another Context in the current account:

        PS> Get-GithubReleases -Account <autocompleted_account> -Context <autocomplete_context> <autocomplete_repo>


    .LINK
        
#>

function New-GithubBranch {

    [CmdletBinding()]
    [Alias('git-branch')]
    param (
        [Parameter(
            Position = 3,
            Mandatory = $false
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-GithubAccountContext -ListAvailable).name
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [validateScript(
            {
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-GithubAccountContext -ListAvailable).name
            }
        )]
        [Alias('a')]
        $Account,

        # The Name of the Github Context to use. Defaults to current Context.
        [Parameter(
            Mandatory = $false,
            Position = 2
        )]
        [ValidateScript(
            { 
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-GithubContexts -Account $PSBoundParameters['Account']).login
            },
            ErrorMessage = 'Please specify an correct Context.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
                $validValues = (Get-GithubContexts -Account $fakeBoundParameters['Account']).login
        
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        [Alias('c')]
        $Context,

        
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

                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        [Alias('r')]
        $Repository,



        # The base branch from which to create another. Defaults to default branch.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Base,

        # Paremter to create a pull request from an issue, identified by issue title, with interactive argument completer.
        [Parameter(
            ParameterSetName = "FromIssueTitle"
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
                $Source = @{
                    Account    = $fakeBoundParameters['Account']
                    Context    = $fakeBoundParameters['Context']
                    Repository = $fakeBoundParameters['Repository']
                }
                $validValues = Get-GithubIssues @Source
                | Where-Object -Property state -EQ open
                | Select-Object -ExpandProperty title

                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $FromIssue
    )

    $repositoryData = Get-GithubRepositoryInfo -Account $Account -Context $Context -Name $Repository

    if ([System.String]::IsNullOrEmpty($base)) {
        $Base = $repositoryData.default_branch
    }

    if ($PSBoundParameters.ContainsKey("FromIssue")) {
        $Issue = Get-GithubIssues -Account $Account -Context $Context -Repository $Repository
        | Where-Object -Property title -EQ $FromIssue

        $target = $Issue.title.toLower().replace(' ', '_')

        git -C $repositoryData.LocalPath fetch origin
        git -C $repositoryData.LocalPath checkout $Base
        git -C $repositoryData.LocalPath checkout -B $target
        git -C $repositoryData.LocalPath push origin $target

    }
    
    else {
        throw "Not Supported"
    }
  
}