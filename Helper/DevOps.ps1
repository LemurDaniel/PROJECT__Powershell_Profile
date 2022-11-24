

function Update-AzDevOpsSecrets {

    $DEVOPS = Get-SecretFromStore -SecretType AZURE_DEVOPS
    $EXPIRES = [System.DateTime] $DEVOPS.EXPIRES
    $TIMESPAN = New-TimeSpan -Start ([System.DateTime]::now) -End $EXPIRES
    if ($TIMESPAN.Days -lt 2) {
        Load-ONEDRIVE_SecretStore
    }
    
}


function Invoke-AzDevOpsRestORG {

    param(
        # Parameter help description
        [Parameter()]
        [System.String]
        [ValidateSet('dev', 'vssps', 'vsaex.dev')]
        $Type = 'dev',

        [Parameter()]
        [System.String]
        $API,

        [Parameter()]
        [System.String]
        [ValidateSet([DevOpsORG])]
        $OrgName = [DevOpsORG]::GetDefaultORG(),

        [Parameter()]
        [System.String]
        $Property = 'value',

        [Parameter()]
        [System.Boolean]
        $Quiet = [System.Boolean]::parse($env:QUIET)
    )


    $TargetUri = "https:///$(Join-Path -Path "$Type.azure.com/baugruppe/" -ChildPath $API)".Replace('\', '/').Replace('//', '/')

    Write-Host '    '$TargetUri

    try {
        $headers = @{ 
            username       = 'my-user-name'
            password       = "Basic $env:AZURE_DEVOPS_HEADER"
            Authorization  = "Basic $env:AZURE_DEVOPS_HEADER"
            'Content-Type' = 'application/x-www-form-urlencoded'
        }

        $response = ''
        if ($Quiet) {
            $response = Invoke-RestMethod -Method GET -Uri $TargetUri -Headers $headers
        }
        else {
            $response = Invoke-RestMethod -Method GET -Uri $TargetUri -Headers $headers
        }

        if ($Property) {
            return ($response.PSObject.Properties | Where-Object { $_.Name -like $Property }).Value 
        }
        else {
            return $response
        }


    }
    catch {
        Write-Host 'ERROR'
        throw $_
    }
   
}

function Get-DevOpsProjectsORG {

    param()

    Get-DevOpsProjects -Org 'baugruppe' #TODO

    <#
        foreach($org in [DevOpsORG]::GetAllORG) {
        

    }
    #>


}

function Get-DevOpsProjects {

    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $Org,

        [Parameter()]
        [System.Boolean]
        $Quiet = [System.Boolean]::parse($env:QUIET)
    )
    Invoke-AzDevOpsRestORG -API '_apis/teams?mine={true}&api-version=6.0-preview.3'

    $projects = Invoke-AzDevOpsRestORG -OrgName $Org -API _apis/projects?api-version=6.0 `
    | Select-Object -Property name, `
    @{Name = 'ShortName'; Expression = { "__$($_.Name)".replace(' ', '') } }, `
    @{Name = 'ReposLocation'; Expression = { $_.Name.replace(' ', '') } }, `
    @{Name = 'Teams'; Expression = {  
            Invoke-AzDevOpsRestORG -OrgName $Org -API "/_apis/projects/$($_.id)/teams?mine={true}&api-version=6.0" }
    }, `
    @{Name = 'Repositories'; Expression = {  
            Invoke-AzDevOpsRestORG -OrgName $Org -API "/$($_.id)/_apis/git/repositories?api-version=4.1" }
    }, `
        visibility, id, url

    Update-SecretStore -SecretType 'DEVOPS_REPOSITORIES_ALL' -SecretValue $projects.Repositories -NoLoad `
                            -SecretStoreSource "ORG" -Organization $Org

    $projects | ForEach-Object { 
        $_.Repositories = ($_.Repositories | Select-Object -Property `
            @{Name = 'Repository'; Expression = {
                    [PSCustomObject]@{
                        id            = $_.id
                        name          = $_.name
                        url           = $_.url
                        remoteUrl     = $_.remoteUrl
                        defaultBranch = $_.defaultBranch
                    
                    }
                }
            }).Repository
    }
   
    Update-SecretStore -SecretType 'DEVOPS_PROJECTS' -SecretValue $projects -NoLoad  -SecretStoreSource "ORG" -Organization $Org
    Update-SecretStore -SecretType AZURE_TENANTS -SecretValue (Get-AzTenant) -NoLoad  -SecretStoreSource "ORG" -Organization $Org
}


##############################################################################################################
##############################################################################################################
##############################################################################################################

function Invoke-AzDevOpsRest {

    param(
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet('GET', 'POST', 'PUT', 'UPDATE', 'DELETE')]
        $Method,

        [Parameter()]
        [System.String]
        [ValidateSet('dev', 'vssps', 'vsaex.dev', 'app.vssps.visualstudio')]
        $Type = 'dev',

        [Parameter()]
        [System.String]
        $API,

        [Parameter()]
        [ValidateSet('ORG', 'PROJ', 'TEAM', 'URI', 'NONE')]
        [System.String]
        $CALL = 'ORG',

        [Parameter()]
        [System.String[]]
        $TeamQuery = @('Azure', 'Migration'),

        [Parameter()]
        [System.Collections.Hashtable]
        $body = @{},

        [Parameter()]
        [System.String]
        $Property = 'value',

        [Parameter()]
        [System.String]
        [ValidateSet([RepoProjects])] # DC-Migration, RD-Redeployment
        $ProjectShort = [RepoProjects]::GetDefaultProject(),

        [Parameter()]
        [System.String]
        [ValidateSet([DevOpsORG])]
        $OrgName = [DevOpsORG]::GetDefaultORG(),

        [Parameter()]
        [System.Boolean]
        $Quiet = [System.Boolean]::parse($env:QUIET)
    )

    $project = [RepoProjects]::GetProject($ProjectShort)
    $team = Get-PreferencedObject -SearchObjects $project.teams -SearchTags $TeamQuery

    $TargetURL = $null
    switch ($CALL) {
        'NONE' {
            $TargetURL = 'https:///' + (Join-Path -Path "$Type.com/" -ChildPath $API) 
        }
        'ORG' { 
            $TargetURL = 'https:///' + (Join-Path -Path "$Type.azure.com/$OrgName/" -ChildPath $API) 
        }
        'PROJ' { 
            $TargetURL = 'https:///' + (Join-Path -Path "$Type.azure.com/$OrgName/$($project.id)" -ChildPath $API) 
        }
        'TEAM' { 
            $TargetURL = 'https:///' + (Join-Path -Path "$Type.azure.com/$OrgName/$($project.id)/$($team.id)" -ChildPath $API) 
        }
        Default {
            $TargetURL = $URI
        }
    }

    $TargetURL = $TargetURL.Replace('\', '/').Replace('//', '/') 
    if (!$TargetURL.contains('api-version')) {
        if ($TargetURL.contains('?')) {
            $TargetURL += '&api-version=7.1-preview.1'
        }
        else {
            $TargetURL += '?api-version=7.1-preview.1'
            $TargetURL = $TargetURL.Replace('/?', '?')
        }
    }

    if (!$Quiet) {
        #Write-Host ($project | ConvertTo-Json)
        #Write-Host ($team | ConvertTo-Json)
        Write-Host 'URL ==> '$TargetURL
        Write-Host 'BODY START'
        Write-Host $body | ConvertTo-Json
        Write-Host 'BODY END'
    }

    try {
        $headers = @{ 
            username       = 'my-user-name'
            password       = "Basic $env:AZURE_DEVOPS_HEADER"
            Authorization  = "Basic $env:AZURE_DEVOPS_HEADER"
            'Content-Type' = $Method.ToLower() -eq 'get' ? 'application/x-www-form-urlencoded' : 'application/json'
        }

        #Write-Host $TargetURL
        $response = Invoke-RestMethod -Method $Method -Uri $TargetURL -Headers $headers -Body ($body | ConvertTo-Json -Compress) -Verbose:(!$Quiet)

        if ($Property) {
            return ($response.PSObject.Properties | Where-Object { $_.Name.toLower() -like $Property.toLower() }).Value 
        }
        else {
            return $response
        }

    }
    catch {
        Write-Host 'ERROR'
        throw $_
    }
   
}
#Invoke-AzDevOpsRest -Method Get -Type vssps -API /_apis/tokens

function Get-WorkItem {
    param(
        [Parameter()]
        [System.String[]]
        $SearchTags
    )

    $currentIteration = Invoke-AzDevOpsRest -Method GET -CALL TEAM -API "/_apis/work/teamsettings/iterations?`$timeframe=current&api-version=6.0"
    $workItems = Invoke-AzDevOpsRest -Method GET -CALL TEAM -Property 'WorkItemRelations' -API "/_apis/work/teamsettings/iterations/$($currentIteration.Id)/workitems?api-version=7.1-preview.1"

    $body = @{
        ids    = $workItems.target.id
        fields = @(
            'System.Id',
            'System.Title',
            'System.AssignedTo',
            'System.WorkItemType',
            'System.Parent',
            'System.PersonId',
            'System.ProjectId',
            'System.Reason',
            'System.RelatedLinkCount',
            'System.RelatedLinks',
            'Microsoft.VSTS.Scheduling.RemainingWork'
        )
    }

    $workItems = (Invoke-AzDevOpsRest -Method POST -CALL PROJ -API '/_apis/wit/workitemsbatch?api-version=7.1-preview.1' -body $body).fields `
    | Where-Object { $_.'System.AssignedTo'.uniqueName -like $env:GitMailWork }

    return Get-PreferencedObject -SearchObjects $workItems -SearchTags $SearchTags -SearchProperty 'System.Title'
}

function New-BranchFromWorkitem {

    [Alias('gitW')]
    param (
        [Parameter()]
        [System.String[]]
        $SearchTags
    )    

    git -C . rev-parse >nul 2>&1; 
    if (!$?) {
        Write-Host 'Please exexcute command inside a Repository'
    }
    else {

        $workItem = Get-WorkItem -SearchTags $SearchTags

        if (!$workItem) {
            Write-Host 'Work Item not found'
            return;
        }

        $transformedTitle = $workItem.'System.Title'.toLower().replace(':', '_').replace('!', '').replace('?', '').replace('/', '-').split(' ') -join '-'

        $branchName = "features/$($workItem.'System.id')-$transformedTitle"
        
        #git stash save "st-$hex" #TODO
        git checkout master
        git pull origin master
        git checkout dev
        git pull origin dev
        git checkout -b "$branchName"
        # git stash pop #TODO

    }

}


function New-MasterPR {

    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $PRtitle
    )

    New-PullRequest -Target 'default' -PRtitle $PRTitle
}

function New-AutomatedTag {

    param()

    $repositoryName = (git rev-parse --show-toplevel).split('/')[-1]
    $repositoryId = Get-PreferencedObject -SearchObjects ([RepoProjects]::GetRepositoriesAll()) -SearchTags "$repositoryName" -returnProperty "id"
    $currentTags = Invoke-AzDevOpsRest -Method GET -CALL PROJ -API "/_apis/git/repositories/$($repositoryId)/refs?filter=tags" | `
        ForEach-Object { return $_.name.split('/')[-1] } | `
        ForEach-Object { return [String]::Format("{0:d4}.{1:d4}.{2:d4}", [int32]::parse($_.split('.')[0]), [int32]::parse($_.split('.')[1]), [int32]::parse($_.split('.')[2])) } | `
        Sort-Object -Descending

    $newTag = "1.0.0"
    if ($currentTags) {
        $currentTags = $currentTags[0].split('.')
        $carry = 1;
        for ($i = $currentTags.length - 1; $i -ge 0; $i--) {
            $nextNum = [int32]::parse($currentTags[$i]) + $carry
            $carry = [math]::floor($nextNum / 10)
            $currentTags[$i] = $nextNum % 10
        }
        $newTag = $currentTags -join '.'
    }   

    $body = @{
        name         = $newTag
        taggedObject = @{
            objectId = git rev-parse HEAD
        }
        message      = "Automated Test Tag ==> $newTag"
    }

    Invoke-AzDevOpsRest -Method POST -Body $body -CALL PROJ -API "/_apis/git/repositories/$($repositoryId)/annotatedtags"

    Write-Host "🎉 New Tag '$newTag' created  🎉"

}

function New-PullRequest {

    param(
        [Parameter()]
        [System.String]
        $PRtitle = $null,

        [Parameter()]
        [ValidateSet('dev', 'master', 'default')]
        [System.String]
        $Target = 'dev',

        [Parameter()]
        [System.String]
        $repositoryId,

        [Parameter()]
        [System.String]
        $repositoryPath,

        [Parameter()]
        [System.String]
        $projectName,

        [Parameter()]
        [System.Boolean]
        $Quiet = [System.Boolean]::parse($env:QUIET)
    )

    try {

        # Get Repo name
        if (-not $repositoryId -OR -not $repositoryPath -OR -not $projectName) {
            $repositoryName = (git rev-parse --show-toplevel).split('/')[-1]
            $preferencedRepo = Get-PreferencedObject -SearchObjects ([Repoprojects]::GetRepositoriesAll()) -SearchTags $repositoryName -SearchProperty 'remoteUrl'
                
            $repositoryId = $preferencedRepo.id
            $projectName = $preferencedRepo.remoteUrl.split('/')[4]
            $repositoryPath = (git rev-parse --show-toplevel)
        }
        
        
        # Search branch by name
        $repositoryName = (git -C $repositoryPath rev-parse --show-toplevel).split('/')[-1]
        $currentBranch = git -C $repositoryPath branch --show-current
        git -C $repositoryPath push --set-upstream origin $currentBranch
        $remoteBranches = Invoke-AzDevOpsRest -Method GET -CALL PROJ -API "/_apis/git/repositories/$($repositoryId)/refs"
        $preferencedBranch = Get-PreferencedObject -SearchObjects $remoteBranches -SearchTags $currentBranch
        # $workItem = Get-WorkItem -SearchTags $currentBbranch

        $hasDevBranch = ($remoteBranches | Where-Object { $_.name.toLower().contains('dev') } | Measure-Object).Count -gt 0
        $hasMainBranch = ($remoteBranches | Where-Object { $_.name.toLower().contains('main') } | Measure-Object).Count -gt 0
        $hasMasterBranch = ($remoteBranches | Where-Object { $_.name.toLower().contains('master') } | Measure-Object).Count -gt 0

        if (-not $hasDevBranch -AND $Target -eq 'dev') {
            throw 'Repository has no DEV Branch Set Up'
        }

        if ($Target -eq 'default') {
            $Target = $hasMasterBranch ? 'master' : 'main'   
            $preferencedBranch = $remoteBranches | Where-Object { $_.name.toLower().contains('dev') }
            $branchName = 'DEV'
        }
        else {
            $branchName = $preferencedBranch.name.split('/')[-2..-1] -join ('/')
        }
        $targetBranch = $remoteBranches | Where-Object { $_.name.toLower().contains($Target.ToLower()) }

        ##############################################
        ########## Prepare and create PR  ############
        $PRtitle = $null -ne $PRtitle -AND $PRtitle.Length -gt 3 ? $PRtitle : ($currentBranch -replace 'features/\d*-{1}', '')
        $PRtitle = "$branchName into $($targetBranch.name.split('/')[-1]) - $PRtitle"

        $body = @{
            sourceRefName = $preferencedBranch.name
            targetRefName = $targetBranch.name
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

        if (!$Quiet) {
            $body
        }

        $activePullRequests = Invoke-AzDevOpsRest -Method GET -CALL PROJ -API "/_apis/git/repositories/$($repositoryId)/pullrequests"
        $chosenPullRequest = $activePullRequests | Where-Object { $_.targetRefName -eq $targetBranch.name -AND $_.sourceRefName -eq $preferencedBranch.name }

        if ($chosenPullRequest) {
            $pullRequestId = $chosenPullRequest.pullRequestId
        }
        else {
            $pullRequestId = Invoke-AzDevOpsRest -Method POST -body $body -CALL PROJ -Property 'pullRequestId' -API "/_apis/git/repositories/$($repositoryId)/pullrequests" 
        }

        $projectName = $projectName.replace(' ', '%20')
        $pullRequestUrl = "https://dev.azure.com/baugruppe/$projectName/_git/$($repositoryName)/pullrequest/$pullRequestId"

        Write-Host -Foreground Green '      '
        Write-Host -Foreground Green ' 🎉 New Pull-Request created  🎉  '
        Write-Host -Foreground Green "    $pullRequestUrl "
        Write-Host -Foreground Green '      '

        Start-Process $pullRequestUrl

    } 
    catch {

        $_

    }

}



########################################################################################################
########################################################################################################

function Get-RecentSubmoduleTags {

    param(
        [Parameter()]
        [switch]
        $forceApiCall = $false
    )

    $moduleSourceReference_Cached = Get-SecretFromStore -SecretType MODULE_SOURCE_REF_CACHE
    if ($null -ne $moduleSourceReference_Cached -AND $forceApiCall -ne $true) {
        return $moduleSourceReference_Cached
    }

    Write-Host "Get Newest Tags"

    # Query All Repositories in DevOps
    $devopsRepositories = Invoke-AzDevOpsRest -Method GET -CALL PROJ -API '/_apis/git/repositories/'
    $preferencedRepos = Get-PreferencedObject -SearchObjects $devopsRepositories -SearchTags 'terraform' -SearchProperty 'name' -Multiple  

    foreach ($repository in $preferencedRepos) {

        # Call Api to get all tags on Repository and sort them by newest
        $sortedTags = Invoke-AzDevOpsRest -Method GET -CALL PROJ -API "/_apis/git/repositories/$($repository.id)/refs?filter=tags" | `
            Select-Object -Property `
        @{Name = 'Tag'; Expression = { $_.name.Split('/')[2] } }, `
        @{Name = 'TagIntSorting'; Expression = { 
                return [String]::Format('{0:d4}.{1:d4}.{2:d4}', @($_.name.split('/')[2].Split('.') | ForEach-Object { [int32]::parse($_) })) 
            }
        } | Sort-Object -Property TagIntSorting -Descending
    
        # If no tag is present, skip further processing
        if ($null -eq $sortedTags -OR $sortedTags.Count -eq 0) {
            $repository | Add-Member -MemberType NoteProperty -Name _TagsAssigned -Value $false
            continue
        }
        else {
            $repository | Add-Member -MemberType NoteProperty -Name _TagsAssigned -Value $true

            $regexQuery = "source\s*=\s*`"git::$($repository.remoteUrl.Replace('/', '\/{0,10}'))\/{0,10}[^\/]*?ref=\d+.\d+.\d+`"".Replace('\\/{0,1}', '\/{0,1}')
            $repository | Add-Member -MemberType NoteProperty -Name CurrentTag -Value $sortedTags[0].Tag
            $repository | Add-Member -MemberType NoteProperty -Name regexQuery -Value $regexQuery

            # Following not done, because it misses subpaths on repos like:
            #   - git::https://<...>/terraform-azurerm-acf-monitoring//alert-processing-rules?ref=1.0.52
            #   - git::https://<...>/terraform-azurerm-acf-monitoring//action-groups?ref=1.0.52

            # $regexReplacement = "source = `"git::$($repository.remoteUrl)?ref=$($sortedTags[0].Tag)`""
            #$repository | Add-Member -MemberType NoteProperty -Name regexReplacement -Value $regexReplacement
        }
    
    }

    $preferencedRepos = $preferencedRepos | Where-Object { $_._TagsAssigned }
    Update-SecretStore -SecretType MODULE_SOURCE_REF_CACHE -SecretValue $preferencedRepos -NoLoad

    return $preferencedRepos

}

function Update-ModuleSourcesInPath {

    [cmdletbinding(
        SupportsShouldProcess,
        ConfirmImpact = 'high'
    )]
    param (
        [Parameter()]
        [System.String]
        $replacementPath = $null,

        [Parameter()]
        [switch]
        $forceApiCall = $false
    )

    $totalReplacements = [System.Collections.ArrayList]::new()
    $taggedRepositories = Get-RecentSubmoduleTags -forceApiCall:($forceApiCall)
    $replacementPath = $null -ne $replacementPath -AND $replacementPath.Length -gt 0 ? $replacementPath : ((Get-Location).Path) 
  
    # Implements Confirmation
    if ($PSCmdlet.ShouldProcess("$replacementPath" , 'Do Subfolder Regex-Operations')) {

        # Make Regex Replace on all Child-Items.
        $childitems = Get-ChildItem -Recurse -Path ($replacementPath) -Filter '*.tf' 
        foreach ($tfConfigFile in $childitems) {

            $regexMatchesCount = 0
            $Content = Get-Content -Path $tfConfigFile.FullName

            if ($null -eq $Content -OR $Content.Length -eq 0) {
                continue; # Skip empty files to prevent errors
            }

            # Parse all Repos over file
            foreach ($repository in $taggedRepositories) {
                $regexMatches = [regex]::Matches($Content, $repository.regexQuery)

                :regexMatch foreach ($match in $regexMatches) {             
                    $sourcePath = $match.Value.replace('"', '').split('?ref=')

                    # Skip sources with already most current tag set.
                    if ($sourcePath[1] -eq $repository.CurrentTag) {
                        continue regexMatch;
                    }

                    $regexMatchesCount += 1
                    $sourcePath[0] = $sourcePath[0].replace('source', '').replace('=', '').trim()
                    $sourceWithCurrentTag = "source = `"$($sourcePath[0])?ref=$($repository.CurrentTag)`""
                    # -replace is used, since get-content returns an array of lines of file, not a text string.
                    # And -replace works on Arrays as well, unlike .replace
                    $matcher = $match.Value.Replace('/', '\/').Replace('?', '\?').Replace('.', '\.')
                    $Content = $Content -replace $matcher, $sourceWithCurrentTag
                
                }
            }
            # Only out-file when changes happend. Overwriting files with the same content, caused issues with VSCode git extension
            if ($regexMatchesCount -gt 0) {
                $totalReplacements.Add($tfConfigFile.FullName)
                $Content | Out-File -LiteralPath $tfConfigFile.FullName
            }
        }  
    }

    return $totalReplacements
}


function Update-ModuleSourcesAllRepositories {
    param (
        [Parameter()]
        [System.String]
        $projectName = [RepoProjects]::GetDefaultProject(),

        [Parameter()]
        [switch]
        $forceApiCall = $false
    )
    
    # Peform regex on following last
    $sortOrder = @(
        'terraform-acf-main',
        'terraform-acf-adds',
        'terraform-acf-launchpad'
    )

    if ($forceApiCall) {
        Write-Host -ForegroundColor Yellow 'Fetching Latest Tags'
    }
    else {
        Write-Host -ForegroundColor Yellow 'Fetching Cached Tags'
    }
    $null = Get-RecentSubmoduleTags -forceApiCall:($forceApiCall)
    $allTerraformRepositories = [RepoProjects]::GetRepositories('__DCAzureMigration') | `
        Where-Object { $_.name.contains('terraform') } | `
        Sort-Object -Property { $sortOrder.IndexOf($_.name) }

    foreach ($repository in $allTerraformRepositories) {
    
        Write-Host -ForegroundColor Yellow "Searching Respository '$($repository.name)' locally"
        $repositoryPath = Get-RepositoryVSCode -repositoryId ($repository.id) -NoOpenVSCode

        Write-Host -ForegroundColor Yellow "Update Master and Dev Branch '$($repository.name)'"
        $repoRefs = Invoke-AzDevOpsRest -Method GET -CALL PROJ -API "/_apis/git/repositories/$($repository.id)/refs" | `
            Where-Object { $_.name.contains('dev') -OR $_.name.contains('main') -OR $_.name.contains('master') } | `
            Sort-Object { @('dev', 'main', 'master').IndexOf($_.name.split('/')[-1]) }

        git -C $repositoryPath.FullName checkout ($repoRefs[0].name -split '/')[-1]
        git -C $repositoryPath.FullName pull

        Write-Host -ForegroundColor Yellow 'Search and Replace Submodule Source Paths'
        $replacements = Update-ModuleSourcesInPath -replacementPath ($repositoryPath.FullName) -Confirm:$false

        if ($replacements.Count -eq 0) {
            continue;
        }

        Write-Host -ForegroundColor Yellow 'Create Branch and Pull Request'
        git -C $repositoryPath.FullName checkout -B features/AUTO__Update-Submodule-source-path
        git -C $repositoryPath.FullName Add -A
        git -C $repositoryPath.FullName commit -m 'AUTO--Update Submodule Source Paths'
        git -C $repositoryPath.FullName push origin features/AUTO__Update-Submodule-source-path
        if ($repoRefs[0].name.contains('dev')) {
            New-PullRequest -PRtitle 'DEV - AUTO--Update Submodule Source Paths' -Target 'dev' `
                -repositoryId ($repository.id) -repositoryPath ($repositoryPath.FullName) -projectName ($repository.remoteUrl.split('/')[4])
        }
        else {
            New-PullRequest -PRtitle 'DEV - AUTO--Update Submodule Source Paths' -Target 'default' `
                -repositoryId ($repository.id) -repositoryPath ($repositoryPath.FullName) -projectName ($repository.remoteUrl.split('/')[4])
        }
    }
}
