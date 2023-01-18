
function New-PullRequest {

    [cmdletbinding()]
    param(
        [Parameter()]
        [System.String]
        $PRtitle = $null,

        [Parameter()]
        [ValidateSet('dev', 'default')]
        [System.String]
        $Target = 'dev',

        [Parameter(Mandatory = $false)]
        [System.String]
        $path,

        [Parameter(Mandatory = $false)]
        [System.String]
        $id   
    )

    $repository = Get-RepositoryInfo -path $path -id $id


    $currentBranch = git -C $repository.Localpath branch --show-current
    git -C $repository.Localpath push --set-upstream origin $currentBranch

    $remoteBranches = Get-RepositoryRefs -id $repository.id
    $preferencedBranch = Search-In $remoteBranches -is $currentBranch -return 'name'

    $hasDevBranch = ($remoteBranches | Where-Object -Property Name -EQ -Value 'refs/heads/dev' | Measure-Object).Count -gt 0
    $hasMainBranch = ($remoteBranches | Where-Object -Property Name -EQ -Value 'refs/heads/main' | Measure-Object).Count -gt 0
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
        API    = "/_apis/git/repositories/$($repository.id)/pullrequests"
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
            API      = "/_apis/git/repositories/$($repository.id)/pullrequests"
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

function New-MasterPR {

    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $PRtitle
    )

    New-PullRequest -Target 'default' -PRtitle $PRTitle
}