<#
    .SYNOPSIS
    Create a new Github branch from an issue.

    .DESCRIPTION
    Create a new Github branch from an issue.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Create a Branch name from an Issue:

    PS> New-GithubBranch --FromIssue <autocompleted_issue_title>


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

        $target = [System.String]::Format("{0}-{1}", $Issue.number, $Issue.title).toLower() `
            -replace '[^a-z0-9_-]', '_' `
            -replace '-+', '-' `
            -replace '_+', '_' `
            -replace '_-', '_' `
            -replace '-_', '_' `
            -replace '_$|-$', ''

        git -C $repositoryData.LocalPath fetch origin
        git -C $repositoryData.LocalPath checkout $Base
        git -C $repositoryData.LocalPath checkout -B $target
        git -C $repositoryData.LocalPath push origin $target

    }
    
    else {
        throw "Not Supported"
    }
  
}