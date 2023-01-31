
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

        # A repository path. If not specified will default to current location.
        [Parameter(Mandatory = $false)]
        [System.String]
        $path,

        # A repository id. If not specified will default to current location.
        [Parameter(Mandatory = $false)]
        [System.String]
        $id   
    )

    $repository = Get-RepositoryInfo -path $path -id $id


    $repostoryPath = [System.String]::IsNullOrEmpty($path) ? $repository.Localpath : $path

    $currentBranch = git -C $repostoryPath --show-current
    git -C $repostoryPath push --set-upstream origin $currentBranch

    $remoteBranches = Get-RepositoryRefs -id $repository.id
    $preferencedBranch = Search-In $remoteBranches -has $currentBranch -return 'name'

    $hasDevBranch = ($remoteBranches | Where-Object -Property Name -EQ -Value 'refs/heads/dev' | Measure-Object).Count -gt 0
    #$hasMainBranch = ($remoteBranches | Where-Object -Property Name -EQ -Value 'refs/heads/main' | Measure-Object).Count -gt 0
    $hasMasterBranch = ($remoteBranches | Where-Object -Property Name -EQ -Value 'refs/heads/master' | Measure-Object).Count -gt 0

    if (-not $hasDevBranch -AND $Target -eq 'dev') {
        throw 'Repository has no DEV Branch Set Up'
    }

    if ($Target -eq 'default') {
        $preferencedBranch = 'refs/heads/dev'
        $targetBranch = $hasMasterBranch ? 'refs/heads/master' : 'refs/heads/main' 
        $branchName = 'DEV'
    }
    else {
        $targetBranch = 'refs/heads/dev'
        $branchName = $preferencedBranch
    }


    # Check
    if ($preferencedBranch -eq 'refs/heads/dev' -AND $Target -eq 'dev') {
        throw "Can't create Pullrequest from DEV to itself"
    }

    ##############################################
    ########## Prepare and create PR  ############
    ##############################################
    $PRtitle = ![System.String]::IsNullOrEmpty($PRtitle) ? $PRtitle : ($currentBranch -replace 'features/\d*-{1}', '')
    $PRtitle = "$branchName into $targetBranch - $PRtitle"

    $Request = @{
        Method = 'GET'
        SCOPE  = 'PROJ'
        API    = "/_apis/git/repositories/$($repository.id)/pullrequests?api-version=7.0"
    }
    $activePullRequests = Invoke-DevOpsRest @Request
    $chosenPullRequest = $activePullRequests.value | Where-Object { $_.targetRefName -eq $targetBranch -AND $_.sourceRefName -eq $preferencedBranch }
    $pullRequestId = $chosenPullRequest.pullRequestId

    if (!$pullRequestId) {
        # Request for creating new Pull Request
        $Request = @{
            Method   = 'POST'
            SCOPE    = 'PROJ'
            Property = 'pullRequestId'
            API      = "/_apis/git/repositories/$($repository.id)/pullrequests?api-version=7.0"
            Body     = @{
                sourceRefName = $preferencedBranch
                targetRefName = $targetBranch
                title         = $PRtitle
                description   = $workItem.'System.Title'
                workItemRefs  = @(
                    @{
                        id  = ''#$workItem.'System.id'
                        url = ''#$workItem.'System.id'
                    }
                )
                reviewers     = $()
            }
        }
        $pullRequestId = Invoke-DevOpsRest @Request
    }

    
    $projectName = (Get-ProjectInfo 'name').replace(' ', '%20')
    $pullRequestUrl = "https://dev.azure.com/baugruppe/$projectName/_git/$($repository.name)/pullrequest/$pullRequestId"

    Write-Host -Foreground Green '      '
    Write-Host -Foreground Green ' 🎉 New Pull-Request created  🎉  '
    Write-Host -Foreground Green "    $pullRequestUrl "
    Write-Host -Foreground Green '      '

    Start-Process $pullRequestUrl

}