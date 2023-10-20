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

function New-GithubPullRequest {

    [CmdletBinding()]
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



        # The base branch for the pull request. Defaults to active branch in local repository.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Head,

        # The target branch for the pull request. Defaults to default branch.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Base,


        # Parameters to create a pull request by specifying a title.
        [Parameter(
            ParameterSetName = "FromTitle"
        )]
        [System.String]
        $Title,
        [Parameter(
            ParameterSetName = "FromTitle"
        )]
        [System.String]
        $Body,

        # Paremter to create a pull request from an issue, identified by issue number.
        [Parameter(
            ParameterSetName = "FromIssueNumber"
        )]
        [System.Int32]
        $IssueNumber,

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
                | Select-Object -ExpandProperty title

                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $FromIssue,



        # Flag to create a draft pull request.
        [Parameter()]
        [switch]
        $Draft,

        # Flag to stop opening the pull request in the browser.
        [Parameter()]
        [switch]
        $NoBrowser,

        # Flag to allow modifying pull request of a fork by maintainers of the upstream repository. 
        [Parameter()]
        [switch]
        $MaintainerCanModify
    )

    $repositoryData = Get-GithubRepositoryInfo -Account $Account -Context $Context -Name $Repository
    $localPath = $repositoryData.LocalPath

    if ([System.String]::IsNullOrEmpty($Head)) {
        $Head = git -C $localPath branch --show-current
    }
    if ([System.String]::IsNullOrEmpty($base)) {
        $Base = $repositoryData.default_branch
    }

    # Search for existing pull request for Head and Base.
    $basePullsUrl = $repositoryData.pulls_url -replace '{/number}', ''
    $pullRequest = Invoke-GithubRest -URL $basePullsUrl -Account $repositoryData.Account
    | Where-Object {
        $_.head.ref -EQ $Head -AND $_.base.ref -EQ $Base
    }

    # Create if none
    if ($null -EQ $pullRequest) {

        $Request = @{
            METHOD  = "Post"
            URL     = $basePullsUrl
            Account = $repositoryData.Account
            Body    = @{
                owner                 = $repositoryData.owner.login
                repo                  = $repositoryData.name
                head                  = $head
                base                  = $base
                draft                 = $Draft.IsPresent
                maintainer_can_modify = $MaintainerCanModify.IsPresent
            }
        }

        if ($PSBoundParameters.ContainsKey("IssueNumber")) {
            $null = $Request.Body.Add('issue', $IssueNumber)
        }

        elseif ($PSBoundParameters.ContainsKey("FromIssue")) {
            $Issue = Get-GithubIssues -Account $Account -Context $Context -Repository $Repository
            | Where-Object -Property title -EQ $FromIssue

            $null = $Request.Body.Add('issue', $Issue.number)
        }

        elseif ($PSBoundParameters.ContainsKey('Title')) {
            $Request.Body.title 
            | Add-Member -PassThru -MemberType NoteProperty -Name issue -Value $Title
            | Add-Member -MemberType NoteProperty -Name issue -Value $Body
        }

        $pullRequest = Invoke-GithubRest @Request
        Write-Host ' 🎉 New Pull-Request created! 🎉  '
    }

    else {
        Write-Host ' ✨ Existent Pull Request Found! ✨  '
    }


    if (!$NoBrowser) {
        Start-Process $pullRequest.html_url
    }

    return $pullRequests
}