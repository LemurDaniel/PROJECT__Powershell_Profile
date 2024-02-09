<#
    .SYNOPSIS
    Create a new Pull Request.

    .DESCRIPTION
    Create a new Pull Request.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Create a new Pull-Request from the current branch to the default branch from a title:

    PS> New-GithubPullRequest -Title "Merge some changes"


    .EXAMPLE

    Convert an issue to a Pull-Request from the current branch to master branch:

    PS> New-GithubPullRequest -Base master -FromIssue <auto_completed_title>


    .EXAMPLE

    Create a new Pull-Request in another context, etc:

    PS> New-GithubPullRequest <autocomplete_repo> -Title "Merge some changes" -Base master 
    
    PS> New-GithubPullRequest -Context <autocomplete_context> <autocomplete_repo>

    PS> New-GithubPullRequest -Account <autocompleted_account> -Context <autocomplete_context> <autocomplete_repo>


    .LINK
        
#>

function New-GithubPullRequest {

    [CmdletBinding(
        DefaultParameterSetName = "FromBranch"
    )]
    [Alias('git-pull')]
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
            Position = 0
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Repository' })]
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
                | Where-Object -Property state -EQ open
                | Select-Object -ExpandProperty title

                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $FromIssue,


        # Name the Pull-Request after the branch.
        [Parameter()]
        [switch]
        $FromBranch,

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

    if ([System.String]::IsNullOrEmpty($Head)) {
        $Head = git -C $repositoryData.LocalPath branch --show-current
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
            $null = $Request.Body.Add('title', $Title)
            $null = $Request.Body.Add('body', $Body)
        }

        else {
            $branchName = git -C $repositoryData.LocalPath branch --show-current
            $null = $Request.Body.Add('title', $branchName)
            $null = $Request.Body.Add('body', "")
        }

        $pullRequest = Invoke-GithubRest @Request -Verbose
        Write-Host ' 🎉 New Pull-Request created! 🎉  '
    }

    else {
        Write-Host ' ✨ Existent Pull Request Found! ✨  '
    }


    if (!$NoBrowser) {
        Start-Process $pullRequest.html_url
    }

    return $pullRequest
}