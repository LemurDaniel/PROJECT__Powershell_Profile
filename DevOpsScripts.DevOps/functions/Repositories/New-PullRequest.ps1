
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

        # The target branch.
        [Parameter()]
        [ArgumentCompleter(   
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = @('current', 'dev', 'default')
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }    
        )]
        [System.String]
        $Target,

        # The target source branch. Will default to current branch
        [Parameter(Mandatory = $false)]
        [ArgumentCompleter(   
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = @('dev', 'default')
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }    
        )]
        [System.String]
        $Source,

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
        $RepositoryName,

        # Activates autocompletion on the Pull Request.
        [Parameter()]
        [switch]
        $autocompletion,

        # Delete Source Branch when autocompletion is enabled.
        [Parameter()]
        [switch]
        $deleteSourceBranch,

        # The Merge strategy for autocompletion enabled.
        [Parameter()]
        [ValidateSet(
            'noFastForward',
            'rebase',
            'rebaseMerge',
            'squash'
        )]
        [System.String]
        $mergeStrategy = 'noFastForward',


        # Workitem ids to connect to the Pull Request
        [Parameter()]
        [System.Int32[]]
        $workItemIds = @()
    )

    $displayInformation = 'error'
    $Repository = Get-RepositoryInfo -Project $Project -Name $RepositoryName
    $remoteBranches = Get-RepositoryRefs -Project $repository.project.name -Name $repository.name
    $repostoryPath = ![System.String]::IsNullOrEmpty($repository.currentPath) ? $repository.currentPath : $repository.LocalPath
    $currentBranch = git -C $repostoryPath branch --show-current

    if ([System.String]::IsNullOrEmpty($Source) -OR $Source -eq 'current') {
        git -C $repostoryPath push --set-upstream origin $currentBranch
        $preferencedBranch = "refs/heads/$currentBranch"
    }
    else {
        $preferencedBranch = "refs/heads/$Source"
    }

    $targetBranch = $Target -eq 'default' ? $repository.defaultBranch :  "refs/heads/$Target"
    if ($targetBranch -notin $remoteBranches.Name) {
        throw "Remote branch doesn't exist - $targetBranch"
    }

    # Check
    if ($preferencedBranch -eq $targetBranch) {
        throw "Can't create Pullrequest from itself to itself - '$preferencedBranch' to '$targetBranch'"
    }

    ##############################################
    ########## Prepare and create PR  ############
    ##############################################
    $PRtitle = ![System.String]::IsNullOrEmpty($PRtitle) ? $PRtitle : ($currentBranch -replace 'features/\d*-{1}', '')
    #$sourceBranchName = $preferencedBranch -replace 'refs/heads/'
    #$targetBranchName = $targetBranch -replace 'refs/heads/'
    #$PRtitle = "$sourceBranchName into $targetBranchName - $PRtitle"

    $Request = @{
        Project = $repository.project.name
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
            Project  = $repository.project.name
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
        $displayInformation = ' 🎉 New Pull-Request created! 🎉  '
    }
    else {
        $displayInformation = ' ✨ Existent Pull Request Found! ✨  '
    }


    $pullRequestArtifactUrl = "vstfs:///Git/PullRequestId/$($repository.project.id)%2F$($repository.id)%2F$($pullRequestId)"
    Write-Verbose $pullRequestArtifactUrl

    if ($currentBranch -match 'features\/\d+-') {
        $workItemIds += [regex]::Match($currentBranch , 'features\/\d+-').Value -replace '[^\d]+', ''
    }

    $workItemIds | ForEach-Object {
        try {
            Connect-Workitem -WorkItemId $_ -linkElementUrl $pullRequestArtifactUrl -RelationType 'Artifact Link'
            Update-Workitem -Id $_ -State Active
        }
        catch {
            if (!$_.ErrorDetails.Message.contains('Relation already exists')) {
                throw $_
            }
        }
    }

    if ($autocompletion) {
        $activeMasterPR = $activePullRequests.value | Where-Object { $_.targetRefName -eq 'refs/heads/master' -AND $_.sourceRefName -eq 'refs/heads/dev' }
        if ($activeMasterPR -AND !($preferencedBranch -eq 'refs/heads/dev' -AND $targetBranch -eq 'refs/heads/master')) {
            $activeMasterPRArtifactUrl = "vstfs:///Git/PullRequestId/$($repository.project.id)%2F$($repository.id)%2F$($activeMasterPR.pullRequestId)"
            $workItemIds | ForEach-Object {
                try {
                    Connect-Workitem -WorkItemId $_ -linkElementUrl $activeMasterPRArtifactUrl -RelationType 'Artifact Link'
                }
                catch {
                    if (!$_.ErrorDetails.Message.contains('Relation already exists')) {
                        throw $_
                    }
                }
            }
        }
        
        # Update PR for autocompletion
        $Request = @{
            Project  = $repository.project.name
            Method   = 'PATCH'
            SCOPE    = 'PROJ'
            Property = 'pullRequestId'
            API      = "/_apis/git/repositories/$($repository.id)/pullrequests/$pullRequestId`?api-version=7.0"
            Body     = @{
                AutoCompleteSetBy = @{
                    id = (Get-DevOpsUser).Identity.id
                }
                CompletionOptions = @{
                    deleteSourceBranch = $PSBoundParameters.ContainsKey('deleteSourceBranch')
                    mergeStrategy      = $mergeStrategy
                }
            }
        }
        $pullRequestId = Invoke-DevOpsRest @Request
    }

    $pullRequestUrl = "https://dev.azure.com/baugruppe/$($repository.project.name.replace(' ', '%20'))/_git/$($repository.name)/pullrequest/$pullRequestId"

    Write-Host -Foreground Green '      '
    Write-Host -Foreground Green $displayInformation
    Write-Host -Foreground Green "    $pullRequestUrl "
    Write-Host -Foreground Green '      '
    Start-Process $pullRequestUrl

}