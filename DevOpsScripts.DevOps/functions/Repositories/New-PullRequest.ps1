
<#
    .SYNOPSIS
    Creates a new Pull-Request in Azure DevOps from.

    .DESCRIPTION
    Creates a new Pull-Request in Azure DevOps from one Branch to Dev or Dev to Master.
    Opens it automatically in the Browser.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None.


    .EXAMPLE

    Create a new Pull-Request from the current features branch in the corresponding AzureDevOps Repository:

    PS> New-PullRequest

    .EXAMPLE

    Create a new Pull-Request from the current features branch in the corresponding AzureDevOps Repository:
    - Specify a PR-Title and a target. Dev or default (Main or Master)

    PS> New-PullRequest -PRTitle '<title>'


    .LINK
        
#>
function New-PullRequest {

    [cmdletbinding()]
    param(
        # The PR-Title. If null will be created automatically.
        [Parameter()]
        [System.String]
        $PRtitle = $null,

        # The target branch. Dev or default for (master or main)
        [Parameter()]
        [ValidateSet('dev', 'default')]
        [System.String]
        $Target = 'dev',

        # The target source branch. Will default to current branch
        [Parameter(Mandatory = $false)]
        [System.String]
        $Source,

        # A repository path. If not specified will default to current location.
        #[Parameter(Mandatory = $false)]
        #[System.String]
        #$path,

        # A repository id. If not specified will default to current location.
        #[Parameter(Mandatory = $false)]
        #[System.String]
        #$id,

        # The name of the project, if not set default to the Current-Project-Context.
        [Parameter(
            ParameterSetName = 'projectSpecific',
            Mandatory = $false,
            Position = 1
        )]
        [ValidateScript(
            { 
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-DevOpsProjects).name
            },
            ErrorMessage = 'Please specify an correct Name.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-DevOpsProjects).name 
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Project,
        
        # The Name of the Repository. If null will default to current repository where command is executed.
        [Parameter(
            ParameterSetName = 'projectSpecific',
            Mandatory = $true,
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'currentContext',
            Mandatory = $false,
            Position = 0
        )]
        [ValidateScript(
            { 
                # Todo, somehow by accessing $Project in here
                $true #$_ -in (Get-ProjectInfo -Name $Project 'repositories.name')
            },
            ErrorMessage = 'Please specify a correct Repositoryname.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = Get-ProjectInfo -Name $fakeBoundParameters['Project'] -return 'repositories.name'
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $RepositoryName 
    )

    
    $Repository = Get-RepositoryInfo -Project $Project -Name $RepositoryName
    $Project = $PSBoundParameters.ContainsKey('Project') ? $Project : $repository.project.name

    $remoteBranches = Get-RepositoryRefs -Project $project -Name $repository.name
    
    if ([System.String]::IsNullOrEmpty($Source)) {
        $repostoryPath = ![System.String]::IsNullOrEmpty($repository.currentPath) ? $repository.currentPath : $repository.LocalPath
        $currentBranch = git -C $repostoryPath branch --show-current
        git -C $repostoryPath push --set-upstream origin $currentBranch
        $preferencedBranch = Search-In $remoteBranches -has $currentBranch -return 'name'
    }
    else {
        $preferencedBranch = "refs/heads/$Source"
    }


    $hasDevBranch = ($remoteBranches | Where-Object -Property Name -EQ -Value 'refs/heads/dev' | Measure-Object).Count -gt 0
    $hasMainBranch = ($remoteBranches | Where-Object -Property Name -EQ -Value 'refs/heads/main' | Measure-Object).Count -gt 0
    $hasMasterBranch = ($remoteBranches | Where-Object -Property Name -EQ -Value 'refs/heads/master' | Measure-Object).Count -gt 0

    if (-not $hasDevBranch -AND $Target -eq 'dev') {
        throw 'Repository has no DEV Branch Set Up'
    }
    $targetBranch = $Target -eq 'default' ? $repository.defaultBranch :  'refs/heads/dev'
    if ($targetBranch -notin $remoteBranches.Name) {
        throw "Remote branch doesn't exist - $targetBranch"
    }


    # Check
    if ($preferencedBranch -eq $targetBranch) {
        throw "Can't create Pullrequest from to itself - '$preferencedBranch' to '$targetBranch'"
    }

    ##############################################
    ########## Prepare and create PR  ############
    ##############################################
    $sourceBranchName = $preferencedBranch -replace 'refs/heads/'
    $targetBranchName = $targetBranch -replace 'refs/heads/'
    $PRtitle = ![System.String]::IsNullOrEmpty($PRtitle) ? $PRtitle : ($currentBranch -replace 'features/\d*-{1}', '')
    $PRtitle = "$sourceBranchName into $targetBranchName - $PRtitle"

    $Request = @{
        Project = $project
        Method  = 'GET'
        SCOPE   = 'PROJ'
        API     = "/_apis/git/repositories/$($repository.id)/pullrequests?api-version=7.0"
    }
    $activePullRequests = Invoke-DevOpsRest @Request
    $chosenPullRequest = $activePullRequests.value | Where-Object { $_.targetRefName -eq $targetBranch -AND $_.sourceRefName -eq $preferencedBranch }
    $pullRequestId = $chosenPullRequest.pullRequestId

    if (!$pullRequestId) {
        # Request for creating new Pull Request
        $Request = @{
            Project  = $project
            Method   = 'POST'
            SCOPE    = 'PROJ'
            Property = 'pullRequestId'
            API      = "/_apis/git/repositories/$($repository.id)/pullrequests?api-version=7.0"
            Body     = @{
                sourceRefName = $preferencedBranch
                targetRefName = $targetBranch
                title         = $PRtitle
                description   = $workItem.'System.Title'
                reviewers     = $()
            }
        }
        $pullRequestId = Invoke-DevOpsRest @Request
    }

    $pullRequestUrl = "https://dev.azure.com/baugruppe/$($project.replace(' ', '%20'))/_git/$($repository.name)/pullrequest/$pullRequestId"

    Write-Host -Foreground Green '      '
    Write-Host -Foreground Green ' 🎉 New Pull-Request created 🎉  '
    Write-Host -Foreground Green "    $pullRequestUrl "
    Write-Host -Foreground Green '      '
    Start-Process $pullRequestUrl

}