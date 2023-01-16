


function Invoke-AzDevOpsRest {

  [cmdletbinding()]
  param(
    # Parameter help description
    [Parameter(Mandatory = $true)]
    [System.String]
    [ValidateSet([HttpMethods])]
    $Method,

    [Parameter()]
    [System.String]
    [ValidateSet('dev', 'dev.azure', 'vssps', 'vssps.dev.azure', 'vsaex.dev', 'app.vssps.visualstudio')]
    $Domain = 'dev.azure',

    [Parameter()]
    [ValidateSet('ORG', 'PROJ', 'TEAM', 'URI', 'NONE')]
    [System.String]
    $CALL = 'ORG',

    [Parameter()]
    [System.String]
    $API,

    [Parameter()]
    [PSCustomObject]
    $body,

    [Parameter()]
    [System.String]
    $Property,

    [Parameter()]
    [System.String]
    $Uri,

    [Parameter()]
    [System.String[]]
    $TeamQuery = @('Azure', 'Migration'),

    [Parameter()]
    [System.String]
    [ValidateSet([Project])]
    $ProjectName = [Project]::Default,

    [Parameter()]
    [System.String]
    [ValidateSet([DevOpsOrganization])]
    $Organization = [DevOpsOrganization]::Default,

    [Parameter()]
    [switch]
    $AsArray
  )

  switch ($CALL) {
    'NONE' {
      $TargetURL = "https://$Domain.com/$API"
    }
    'ORG' { 
      $TargetURL = "https://$Domain.com/$Organization/$API"
      continue
    }
    'PROJ' { 
      $project = ([Project]::GetByName($ProjectName))
      $TargetURL = "https://$Domain.com/$Organization/$($project.id)/$API"
    }
    'TEAM' { 
      $project = ([Project]::GetByName($ProjectName))
      $team = Search-Int $project.teams -is $TeamQuery
      $TargetURL = "https://$Domain.com/$Organization/$($project.id)/$($team.id)/$API"
    }
  }

  $token = (Get-AzAccessToken -ResourceUrl '499b84ac-1321-427f-aa17-267ca6975798').Token
  $Request = @{
    Method  = $Method
    Body    = $body | ConvertTo-Json -Compress -AsArray:$AsArray
    Headers = @{ 
      username       = 'O.o'
      password       = $token
      Authorization  = "Bearer $($token)"
      #Authorization    = "Basic $token"
      'Content-Type' = $Method.ToLower() -eq 'get' ? 'application/x-www-form-urlencoded' : 'application/json; charset=utf-8'
    }
    Uri     = $Uri.Length -gt 0 ? $Uri : ($TargetURL -replace '/+', '/' -replace '/$', '' -replace ':/', '://')
  }

  if (!$Request.Uri.contains('api-version')) {
    $Request.Uri += ($Request.Uri.contains('?') ? '&' : '?') + 'api-version=7.1-preview.1'
  }

  Write-Verbose 'BODY START'
  Write-Verbose ($Request | ConvertTo-Json)
  Write-Verbose 'BODY END'

  $response = Invoke-RestMethod @Request

  Write-Verbose ($response | ConvertTo-Json)

  if (![string]::IsNullOrEmpty($Property)) {
    return $response | ForEach-Object { $_."$Property" } 
  }
  else {
    return $response
  }
}

##############################################################################################################
##############################################################################################################
##############################################################################################################


function Get-DevOpsProjects {

  [cmdletbinding()]
  param(
    [Parameter()]
    [ORGANIZATION]
    $Org = $env:AZURE_DEVOPS_ORGANIZATION_CURRENT
  )

  Connect-AzAccount

  $RequestBlueprint = @{
    METHOD       = 'GET'
    CALL         = 'ORG'
    DOMAIN       = 'dev.azure'
    Organization = $Org
  }

  $projects = Invoke-AzDevOpsRest @RequestBlueprint -API '_apis/projects?api-version=6.0' `
  | Select-Object -Property name, `
  @{Name = 'ShortName'; Expression = { "__$($_.Name)".replace(' ', '') } }, `
  @{Name = 'ReposLocation'; Expression = { $_.Name.replace(' ', '') } }, `
  @{Name = 'Teams'; Expression = {  
      Invoke-AzDevOpsRest @RequestBlueprint -API "/_apis/projects/$($_.id)/teams?mine={true}&api-version=6.0" }
  }, `
  @{Name = 'Repositories'; Expression = {  
      Invoke-AzDevOpsRest @RequestBlueprint -API "/$($_.id)/_apis/git/repositories?api-version=4.1" }
  }, `
    visibility, id, url

  Update-SecretStore ORG $ORG -SecretPath CACHE.DEVOPS_REPOSITORIES_ALL -SecretValue $projects.Repositories

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
   
  Update-SecretStore ORG $ORG -SecretPath CACHE.DEVOPS_PROJECTS -SecretValue $projects
  Update-SecretStore ORG $ORG -SecretPath CACHE.AZURE_TENANTS -SecretValue (Get-AzTenant)

}

##############################################################################################################
##############################################################################################################
##############################################################################################################

function Get-RepositoryInfo {

  param ( 
    [Parameter()]
    [System.String]
    $repositoryPath
  )    

  $repositoryPath = [System.String]::IsNullOrEmpty($repositoryPath) ? (Get-Location) : $repositoryPath
  $repositoryPath = (git -C $repositoryPath rev-parse --show-toplevel)
  $project = [Project]::GetByPath($repositoryPath)
  $repositoryName = $repositoryPath.split('/')[-1]
  $preferencedRepo = Search-In ([Repository]::GetByProjectName($project.name)) -where 'name' -is $repositoryName  
  
  return [PSCustomObject]@{
    Project        = $project
    Repository     = $preferencedRepo
    RepositoryPath = $repositoryPath
  }
}

function Get-RepositoryRefs {

  param ( 
    [Parameter()]
    [System.String]
    $repositoryPath,

    [Parameter()]
    [System.String]
    $repositoryId
  )  

  $repositoryId = [System.String]::IsNullOrEmpty($repositoryId) ? ((Get-RepositoryInfo -repositoryPath $repositoryPath).Repository.id) : $repositoryId
  $Request = @{
    METHOD   = 'GET'
    CALL     = 'PROJ'
    API      = "/_apis/git/repositories/$($repositoryId)/refs"
    Property = 'value'
  }
  return Invoke-AzDevOpsRest @Request 
}

# Remove Automated tags created for testing again.
function Remove-AutomatedTags {

  param()

  $currentTags = Get-RepositoryRefs | Where-Object { $_.name.contains('tags') }
  $Request = @{
    Method  = 'POST'
    CALL    = 'PROJ'
    API     = "/_apis/git/repositories/$((Get-RepositoryInfo).Repository.id)/refs?api-version=6.1-preview.1"
    AsArray = $true
    Body    = @(
      $currentTags | `
        Where-Object { $_.creator.uniqueName -eq $env:ORG_GIT_MAIL } | `
        ForEach-Object {
        @{
          repositoryId = $repositoryId
          name         = $_.name
          oldObjectId  = $_.objectId
          newObjectId  = '0000000000000000000000000000000000000000'  
        }
      }
    ) 
  }

  Invoke-AzDevOpsRest @Request 
}

function New-AutomatedTag {

  param()

  $currentTags = Get-RepositoryRefs | Where-Object { $_.name.contains('tags') | `
      ForEach-Object { return $_.name.split('/')[-1] } | `
      ForEach-Object { 
      return [String]::Format('{0:d4}.{1:d4}.{2:d4}', 
        [int32]::parse($_.split('.')[0]), [int32]::parse($_.split('.')[1]), 
        [int32]::parse($_.split('.')[2]))
    } } | Sort-Object -Descending

  $newTag = '1.0.0'
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

  $Request = @{
    Method = 'POST'
    CALL   = 'PROJ'
    API    = "/_apis/git/repositories/$((Get-RepositoryInfo).Repository.id)/annotatedtags"
    Body   = @{
      name         = $newTag
      taggedObject = @{
        objectId = git rev-parse HEAD
      }
      message      = "Automated Test Tag ==> $newTag"
    }
  }
  Invoke-AzDevOpsRest @Request

  Write-Host "🎉 New Tag '$newTag' created  🎉"
}

########################################################################################################
########################################################################################################

function Get-WorkItem {
  param(
    [Parameter()]
    [System.String[]]
    $SearchTags
  )

  $Request = @{
    Method = 'GET'
    CALL   = 'PROJ'
    API    = "/_apis/work/teamsettings/iterations?`$timeframe=current&api-version=7.0"
  }
  $currentIteration = Invoke-AzDevOpsRest @Request
  $Request = @{
    Method   = 'GET'
    CALL     = 'PROJ'
    Property = 'WorkItemRelations'
    API      = "/_apis/work/teamsettings/iterations/$($currentIteration.Id)/workitems?api-version=7.1-preview.1"
  }
  $workItems = Invoke-AzDevOpsRest @Request

  $Request = @{
    Method = 'POST'
    CALL   = 'PROJ'
    API    = '/_apis/wit/workitemsbatch?api-version=7.1-preview.1'
    Body   = @{
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
  }
  $workItems = (Invoke-AzDevOpsRest @Request).fields | Where-Object { $_.'System.AssignedTo'.uniqueName -like $env:ORG_GIT_MAIL }
  return Search-In $workItems -where '(System.Title)' -is $SearchTags 
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

    $transformedTitle = $workItem.'System.Title'.toLower() -replace '[?!:\/\\\-]+', '_'
    $branchName = "features/$($workItem.'System.id')-$transformedTitle"
        
    git checkout master
    git pull origin master
    git checkout dev
    git pull origin dev
    git checkout -b "$branchName"

  }

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
    $repositoryPath
  )

  $info = Get-RepositoryInfo -repositoryPath $repositoryPath
  $repositoryPath = $info.RepositoryPath
  $remoteBranches = Get-RepositoryRefs -repositoryPath $repositoryPath


  $currentBranch = git -C $repositoryPath branch --show-current
  git -C $repositoryPath push --set-upstream origin $currentBranch
  $preferencedBranch = Search-In $remoteBranches -is $currentBranch

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

  $activePullRequests = Invoke-AzDevOpsRest -Method GET -CALL PROJ -API "/_apis/git/repositories/$($info.Repository.id)/pullrequests"
  $chosenPullRequest = $activePullRequests | Where-Object { $_.targetRefName -eq $targetBranch.name -AND $_.sourceRefName -eq $preferencedBranch.name }

  Write-Verbose $chosenPullRequest.pullRequestId
  if ($chosenPullRequest) {
    $pullRequestId = $chosenPullRequest.pullRequestId
  }
  else {
    # Request for creating new Pull Request
    $Request = @{
      Method   = 'POST'
      CALL     = 'PROJ'
      Property = 'pullRequestId'
      API      = "/_apis/git/repositories/$($info.Repository.id)/pullrequests"
      Body     = @{
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
    }
    $pullRequestId = Invoke-AzDevOpsRest @Request
  }

  $projectName = $info.Project.name.replace(' ', '%20')
  $pullRequestUrl = "https://dev.azure.com/baugruppe/$projectName/_git/$($info.Repository.name)/pullrequest/$pullRequestId"

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

########################################################################################################
########################################################################################################

function Get-RecentSubmoduleTags {

  param(
    [Parameter()]
    [switch]
    $forceApiCall = $false
  )


  $moduleSourceReference_Cached = Get-SecretFromStore CACHE.MODULE_SOURCE_REF -ErrorAction SilentlyContinue
  if ($null -ne $moduleSourceReference_Cached -AND $forceApiCall -ne $true) {
    Write-Host -ForegroundColor Yellow 'Fetching Cached Tags'
    return $moduleSourceReference_Cached
  }

  Write-Host -ForegroundColor Yellow 'Fetching Latest Tags'

  # Query All Repositories in DevOps
  $devopsRepositories = Invoke-AzDevOpsRest -Method GET -CALL PROJ -API '/_apis/git/repositories/'
  $preferencedRepos = Search-In $devopsRepositories -is 'terraform' -Multiple  

  foreach ($repository in $preferencedRepos) {

    # Call Api to get all tags on Repository and sort them by newest
    $sortedTags = Get-RepositoryRefs -repositoryId $repository.id | Where-Object { $_.name.contains('tags') } | `
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
  Update-SecretStore ORG -SecretPath CACHE.MODULE_SOURCE_REF -SecretValue $preferencedRepos

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
    $projectName = [Projects]::Default(),

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

  $forceFeatureBranch = @(
    'terraform-acf-main',
    'terraform-acf-adds',
    'terraform-acf-launchpad'
  )



  $null = Get-RecentSubmoduleTags -forceApiCall:($forceApiCall)
  $allTerraformRepositories = [Repository]::GetByProjectName($projectName) | `
    Where-Object { $_.name.contains('terraform') } | `
    Sort-Object -Property { $sortOrder.IndexOf($_.name) }

  foreach ($repository in $allTerraformRepositories) {
    
    Write-Host -ForegroundColor Yellow "Searching Respository '$($repository.name)' locally"
    $repositoryPath = Get-RepositoryVSCode -repositoryId ($repository.id) -onlyDownload

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



    # Case when feature branch is needed
    if ($forceFeatureBranch.Contains($repository.name)) {
        
      Write-Host -ForegroundColor Yellow 'Create Feature Branch and create Pull Request'
      git -C $repositoryPath.FullName checkout -B features/AUTO__Update-Submodule-source-path
      git -C $repositoryPath.FullName add -A
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
    else {
        
      Write-Host -ForegroundColor Yellow 'Update Dev Branch and create Pull Request'
      git -C $repositoryPath.FullName checkout -B dev
      git -C $repositoryPath.FullName add -A
      git -C $repositoryPath.FullName commit -m 'AUTO--Update Submodule Source Paths'
      git -C $repositoryPath.FullName push origin dev
        
      New-PullRequest -PRtitle 'DEV - AUTO--Update Submodule Source Paths' -Target 'default' `
        -repositoryId ($repository.id) -repositoryPath ($repositoryPath.FullName) -projectName ($repository.remoteUrl.split('/')[4])

    }
  }
}

########################################################################################################
########################################################################################################

function Edit-RegexOnFiles {

  [cmdletbinding(
    SupportsShouldProcess,
    ConfirmImpact = 'high'
  )]
  param (
    [Parameter()]
    [System.String]
    $replacementPath = $null,

    # Parameter help description.
    [Parameter()]
    [System.String]
    $replace = '',

    # Parameter help description.
    [Parameter(Mandatory = $true)]
    [System.String]
    $regexQuery
  )

  $totalReplacements = [System.Collections.ArrayList]::new()
  $replacementPath = $null -ne $replacementPath -AND $replacementPath.Length -gt 0 ? $replacementPath : ((Get-Location).Path) 
  
  # Implements Confirmation handling.
  if ($PSCmdlet.ShouldProcess("$replacementPath" , 'Remove Moved-Blocks on Folderpath')) {

    # Make Regex Replace on all Child-Items.
    $childFiles = Get-ChildItem -Recurse -Path ($replacementPath) -Filter '*.tf' | `
      ForEach-Object { 
      [PSCustomObject]@{
        FullName = $_.FullName
        Content  = (Get-Content -Path $_.FullName -Raw)
      } 
    } | Where-Object { $null -ne $_.Content -AND $_.Content.Length -ne 0 }


    foreach ($file in $childFiles) {

      # Find Regexmatches.
      $regexMatches = [regex]::Matches($file.Content, $regexQuery)
      if (($regexMatches | Measure-Object).Count -le 0) {
        continue
      }
      
      :regexMatch 
      foreach ($match in $regexMatches) {     
        # -replace is used, since get-content returns an array of lines of file, not a text string.
        # And -replace works on Arrays as well, unlike .replace
        $file.Content = $file.Content -replace ($match.Value), $replace
      }

      $file.Content | Out-File -LiteralPath $file.FullName
    }  
  }

  return $totalReplacements
}


function Remove-MovedBlocks {

  param ()

  # Remove Moved-Blocks from Terraform configuration.
  Edit-RegexOnFiles -regexQuery 'moved\s*{[a-zA-Z=_.\-\s]*}'
  
}



########################################################################################################
########################################################################################################

function Start-PipelineOnBranch {
  param (
    [Parameter()]
    [System.int32]
    $id,

    [Parameter()]
    [System.String]
    $ref
  )
  
  # Run Pipeline.
  $Request = @{
    ProjectName = $projectName
    Method      = 'POST'
    Domain      = 'dev.azure'
    CALL        = 'PROJ'
    API         = '/_apis/build/builds?api-version=6.0'
    Body        = @{
      definition   = @{ id = $_.id }
      sourceBranch = $ref
    }
  }
  return Invoke-AzDevOpsRest @Request

}


function Start-Pipeline {
  [cmdletbinding()]
  param (
    [Parameter()]
    [Alias('is')]
    [System.String[]]
    $SearchTags,

    [Parameter()]
    [Alias('not')]
    [System.String[]]
    $excludedTags = @(),

    [Parameter()]
    [ValidateSet('Branch', 'Dev', 'Master', 'Both')]
    [System.String]
    $environment = 'Branch',

    [Parameter()]
    [switch]
    $Multiple
  )

  $info = Get-RepositoryInfo
  $organization = $env:AZURE_DEVOPS_ORGANIZATION_CURRENT
  $projectName = $info.Project.name
  $projectNameUrlEncoded = $info.Project.name -replace ' ', '%20'
  
  # Get Pipelines.
  $Request = @{
    ProjectName = $projectName
    Method      = 'GET'
    Domain      = 'dev.azure'
    CALL        = 'PROJ'
    API         = '_apis/pipelines?api-version=7.0'
  }
  $Pipelines = Invoke-AzDevOpsRest @Request
  
  # Search Pipelines by tags.
  $Pipelines = Search-In $Pipelines -where 'name' -is $SearchTags -not $excludedTags -Multiple:$Multiple

  # Action for each Pipeline.
  $Pipelines | ForEach-Object { 

    # Run Pipeline from Branch, dev or master
    if ($environment -eq 'Branch') {
      $remoteBranches = Get-RepositoryRefs -repositoryId $info.Repository.id
      $currentBranch = git branch --show-current
      $branch = Search-PreferencedObject -SearchObjects $remoteBranches -SearchTags $currentBranch
      Start-PipelineOnBranch -id $_.id -ref $branch.name
    }

    if ($environment -eq 'dev' -OR $environment -eq 'both') {
      Start-PipelineOnBranch -id $_.id -ref 'refs/heads/dev'
    }

    if ($environment -eq 'master' -OR $environment -eq 'both') {
      Start-PipelineOnBranch -id $_.id -ref 'refs/heads/master'
    }

    # Open in Browser.
    $pipelineUrl = "https://dev.azure.com/$organization/$projectNameUrlEncoded/_build?definitionId=$($_.id)"

    Write-Host -Foreground Green '      '
    Write-Host -Foreground Green " 🎉 Started Pipeline '$($_.folder)/folder$($_.name)'  on $environment 🎉  "
    Write-Host -Foreground Green "    $pipelineUrl "
    Write-Host -Foreground Green '      '

    Start-Process $pipelineUrl
  }

}