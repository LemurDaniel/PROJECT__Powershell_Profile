

function Update-AzDevOpsSecrets {

    $DEVOPS = Get-PersonalSecret -SecretType AZURE_DEVOPS
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
        [ValidateSet("dev", "vssps", "vsaex.dev")]
        $Type = "dev",

        [Parameter()]
        [System.String]
        $API,

        [Parameter()]
        [System.String]
        [ValidateSet([DevOpsORG])]
        $OrgName = [DevOpsORG]::GetDefaultORG(),

        [Parameter()]
        [System.String]
        $Property = "value",

        [Parameter()]
        [System.Boolean]
        $Quiet = [System.Boolean]::parse($env:QUIET)
    )


    $TargetUri = "https:///$(Join-Path -Path "$Type.azure.com/baugruppe/" -ChildPath $API)".Replace("\", "/").Replace("//", "/")

    Write-Host "    "$TargetUri

    try {
        $headers = @{ 
            username       = "my-user-name"
            password       = "Basic $env:AZURE_DEVOPS_HEADER"
            Authorization  = "Basic $env:AZURE_DEVOPS_HEADER"
            "Content-Type" = "application/x-www-form-urlencoded"
        }

        $response = ""
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
        Write-Host "ERROR"
        throw $_
    }
   
}

function Get-DevOpsProjectsORG {

    param()

    Get-DevOpsProjects -$Org "baugruppe" #TODO
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
    Invoke-AzDevOpsRestORG -API "_apis/teams?mine={true}&api-version=6.0-preview.3"

    $projects = Invoke-AzDevOpsRestORG -OrgName $Org -API _apis/projects?api-version=6.0 `
    | Select-Object -Property name, `
    @{Name = "ShortName"; Expression = { "__$($_.Name)".replace(" ", "") } }, `
    @{Name = "ReposLocation"; Expression = { $_.Name.replace(" ", "") } }, `
    @{Name = "Teams"; Expression = {  
            Invoke-AzDevOpsRestORG -OrgName $Org -API "/_apis/projects/$($_.id)/teams?mine={true}&api-version=6.0" }
    }, `
    @{Name = "Repositories"; Expression = {  
            Invoke-AzDevOpsRestORG -OrgName $Org -API "/$($_.id)/_apis/git/repositories?api-version=4.1" }
    }, ` 
    visibility, id, url

    Update-PersonalSecret -SecretType "DEVOPS_REPOSITORIES_ALL" -SecretValue $projects.Repositories -NoLoad

    $projects | ForEach-Object { 
        $_.Repositories = ($_.Repositories | Select-Object -Property `
            @{Name = "Repository"; Expression = {
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
   
    Update-PersonalSecret -SecretType "DEVOPS_PROJECTS" -SecretValue $projects -NoLoad
}


##############################################################################################################
##############################################################################################################
##############################################################################################################

function Invoke-AzDevOpsRest {

    param(
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("GET", "POST", "PUT", "UPDATE", "DELETE")]
        $Method,

        [Parameter()]
        [System.String]
        [ValidateSet("dev", "vssps", "vsaex.dev", "app.vssps.visualstudio")]
        $Type = "dev",

        [Parameter()]
        [System.String]
        $API,

        [Parameter()]
        [ValidateSet("ORG", "PROJ", "TEAM", "URI", "NONE")]
        [System.String]
        $CALL = "ORG",

        [Parameter()]
        [System.String[]]
        $TeamQuery = @("Azure", "Migration"),

        [Parameter()]
        [System.Collections.Hashtable]
        $body = @{},

        [Parameter()]
        [System.String]
        $Property = "value",

        [Parameter()]
        [System.String]
        [ValidateSet([RepoProjects])] # DC-Migration, RD-Redeployment
        $ProjectShort = [DevOpsORG]::GetDefaultProject(),

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
        "NONE" {
            $TargetURL = "https:///" + (Join-Path -Path "$Type.com/" -ChildPath $API) 
        }
        "ORG" { 
            $TargetURL = "https:///" + (Join-Path -Path "$Type.azure.com/$OrgName/" -ChildPath $API) 
        }
        "PROJ" { 
            $TargetURL = "https:///" + (Join-Path -Path "$Type.azure.com/$OrgName/$($project.id)" -ChildPath $API) 
        }
        "TEAM" { 
            $TargetURL = "https:///" + (Join-Path -Path "$Type.azure.com/$OrgName/$($project.id)/$($team.id)" -ChildPath $API) 
        }
        Default {
            $TargetURL = $URI
        }
    }

    $TargetURL = $TargetURL.Replace("\", "/").Replace("//", "/") 
    if (!$TargetURL.contains("api-version")) {
        if ($TargetURL.contains("?")) {
            $TargetURL += "&api-version=7.1-preview.1"
        }
        else {
            $TargetURL += "?api-version=7.1-preview.1"
            $TargetURL = $TargetURL.Replace("/?", "?")
        }
    }

    if (!$Quiet) {
        #Write-Host ($project | ConvertTo-Json)
        #Write-Host ($team | ConvertTo-Json)
        Write-Host "URL ==> "$TargetURL
        Write-Host "BODY START"
        Write-Host $body | ConvertTo-Json
        Write-Host "BODY END"
    }

    try {
        $headers = @{ 
            username       = "my-user-name"
            password       = "Basic $env:AZURE_DEVOPS_HEADER"
            Authorization  = "Basic $env:AZURE_DEVOPS_HEADER"
            "Content-Type" = $Method.ToLower() -eq "get" ? "application/x-www-form-urlencoded" : "application/json"
        }

        $response = Invoke-RestMethod -Method $Method -Uri $TargetURL -Headers $headers -Body ($body | ConvertTo-Json -Compress) -Verbose:(!$Quiet)

        if ($Property) {
            return ($response.PSObject.Properties | Where-Object { $_.Name.toLower() -like $Property.toLower() }).Value 
        }
        else {
            return $response
        }

    }
    catch {
        Write-Host "ERROR"
        throw $_
    }
   
}
#Invoke-AzDevOpsRest -Method Get -Type vssps -API /_apis/tokens

function Get-WorkItemBranch {

}
function Get-WorkItem {
    param(
        [Parameter()]
        [System.String[]]
        $SearchTags
    )

    $currentIteration = Invoke-AzDevOpsRest -Method GET -CALL TEAM -API "/_apis/work/teamsettings/iterations?`$timeframe=current&api-version=6.0"
    $workItems = Invoke-AzDevOpsRest -Method GET -CALL TEAM -Property "WorkItemRelations" -API "/_apis/work/teamsettings/iterations/$($currentIteration.Id)/workitems?api-version=7.1-preview.1"

    $body = @{
        ids    = $workItems.target.id
        fields = @(
            "System.Id",
            "System.Title",
            "System.AssignedTo",
            "System.WorkItemType",
            "System.Parent",
            "System.PersonId",
            "System.ProjectId",
            "System.Reason",
            "System.RelatedLinkCount",
            "System.RelatedLinks",
            "Microsoft.VSTS.Scheduling.RemainingWork"
        )
    }

    $workItems = (Invoke-AzDevOpsRest -Method POST -CALL PROJ -API "/_apis/wit/workitemsbatch?api-version=7.1-preview.1" -body $body).fields `
    | Where-Object { $_.'System.AssignedTo'.uniqueName -like $env:GitMailWork }

    return Get-PreferencedObject -SearchObjects $workItems -SearchTags $SearchTags -SearchProperty "System.Title"
}

function New-BranchFromWorkitem {

    [Alias("gitW")]
    param (
        [Parameter()]
        [System.String[]]
        $SearchTags
    )    

    git -C . rev-parse >nul 2>&1; 
    if (!$?) {
        Write-Host "Please exexcute command inside a Repository"
    }
    else {

        $workItem = Get-WorkItem -SearchTags $SearchTags

        if (!$workItem) {
            Write-Host "Work Item not found"
            return;
        }

        $transformedTitle = $workItem.'System.Title'.toLower().replace(':', '_').replace('!', '').replace('?', '').split(' ') -join '-'

        $branchName = "features/$($workItem.'System.id')-$transformedTitle"

        $byteArray = [System.BitConverter]::GetBytes((Get-Random))
        $hex = [System.Convert]::ToHexString($byteArray)
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
        [Parameter()]
        [System.String]
        $PR_title = "Merge DEV into MASTER",

        [Parameter()]
        [System.Boolean]
        $Approve = $false,

        [Parameter()]
        [System.Boolean]
        $Quiet = [System.Boolean]::parse($env:QUIET)
    )

    try {

        # Get Repo name
        $repository_name = (git rev-parse --show-toplevel).split('/')[-1]
    
        $preferenced_repo = Get-PreferencedObject -SearchObjects ([Repoprojects]::GetRepositoriesAll()) -SearchTags $repository_name -SearchProperty  "remoteUrl"

        $active_pull_requests = Invoke-AzDevOpsRest -Method GET -CALL PROJ -API "/_apis/git/repositories/$($preferenced_repo.id)/pullrequests"
        $chosen_pull_request = $active_pull_requests | Where-Object { $_.targetRefName -eq "refs/heads/master" }

        if (!$chosen_pull_request -or $chosen_pull_request.sourceRefName -eq "refs/heads/hotfix") {

            $body = @{
                sourceRefName = "refs/heads/dev"
                targetRefName = $preferenced_repo.defaultBranch.trim()
                title         = "Merge branch DEV into Master"
                description   = "Merge branch DEV into Master" 
                reviewers     = $(
                    #{
                    #  "id": "d6245f20-2af8-44f4-9451-8107cb2767db"
                    #}
                )
            }

            $chosen_pull_request = Invoke-AzDevOpsRest -Method POST -body $body -CALL PROJ -Property $null -API "/_apis/git/repositories/$($preferenced_repo.id)/pullrequests" 

        }
        elseif ($approve) {

            $pull_request_id = $chosen_pull_request.pullRequestId

            <#
            $body = @{
                reviewerUrl= "https://dev.azure.com/baugruppe/625cb37d-7374-4306-b7e9-98f0ef6958a5/_apis/git/repositories/264e303e-07e9-4e8b-bb65-d9f0650b4e2b/pullRequests/28290/reviewers/4a75589a-39ce-663a-92d1-15abe18cefce"
                vote= 10
                hasDeclined= $false
                isFlagged= $false
                displayName= "Daniel Landau"
                url= "https://spsprodweu4.vssps.visualstudio.com/A54e75587-863e-4464-80fe-12ab77c3d304/_apis/Identities/4a75589a-39ce-663a-92d1-15abe18cefce"
                links= @{
                  avatar= @{
                    href= "https://dev.azure.com/baugruppe/_apis/GraphProfile/MemberAvatars/aad.NGE3NTU4OWEtMzljZS03NjNhLTkyZDEtMTVhYmUxOGNlZmNl"
                  }
                }
                id= "4a75589a-39ce-663a-92d1-15abe18cefce"
                uniqueName= "daniel.landau@brz.eu"
                imageUrl= "https://dev.azure.com/baugruppe/_api/_common/identityImage?id=4a75589a-39ce-663a-92d1-15abe18cefce"
              }
              
            $body = @{
                id = "4a75589a-39ce-663a-92d1-15abe18cefce"
                vote = 0
            }
           # 4a75589a-39ce-663a-92d1-15abe18cefce
            $body = @{
                displayName = "Daniel Landau"
                uniqueName="daniel.landau@brz.eu"
                hasDeclined = $false
                id = "4a75589a-39ce-663a-92d1-15abe18cefce"
                vote = 10
                url = "https://spsprodweu4.vssps.visualstudio.com/A54e75587-863e-4464-80fe-12ab77c3d304/_apis/Identities/4a75589a-39ce-663a-92d1-15abe18cefce?api-version=6.0"
              }
           # Invoke-AzDevOpsRest -Method POST -body $body   /_apis/userentitlements
            $approve_pr = Invoke-AzDevOpsRest -Method POST -body $body -API_Project "/_apis/git/repositories/$repository_id/pullRequests/$pull_request_id/reviewers/4a75589a-39ce-663a-92d1-15abe18cefce?api-version=6.0"
#>
        }

        $pull_request_id = $chosen_pull_request.pullRequestId
        $project_name = $preferenced_repo.project.name.replace(" ", "%20")
        $pull_request_url = "https://dev.azure.com/baugruppe/$project_name/_git/$($preferenced_repo.name)/pullrequest/$pull_request_id"

        Start-Process $pull_request_url
        
    } 
    catch {

        $_

    }
}

function New-PullRequest {

    param(
        [Parameter()]
        [System.String]
        $PR_title = $null,

        [Parameter()]
        [System.Boolean]
        $Quiet = [System.Boolean]::parse($env:QUIET)
    )

    try {

        # Get Repo name
        $repository_name = (git rev-parse --show-toplevel).split('/')[-1]
        $preferenced_repo = Get-PreferencedObject -SearchObjects ([Repoprojects]::GetRepositoriesAll()) -SearchTags $repository_name -SearchProperty  "remoteUrl"
 
        # Search branch by name
        $current_branch = git branch --show-current
        $remote_branches = Invoke-AzDevOpsRest -Method GET -CALL PROJ  -API "/_apis/git/repositories/$($preferenced_repo.id)/refs"

        $preferenced_branch = Get-PreferencedObject -SearchObjects $remote_branches -SearchTags $current_branch
        $workItem = Get-WorkItem -SearchTags $current_branch

        ##############################################
        ########## Prepare and create PR  ############

        if ($PR_title -eq $null -or $PR_title.length -lt 3) {
            $branch_name = $preferenced_branch.name.split('/')[-2..-1] -join ('/')
            $PR_title = "Merge branch $branch_name into DEV"
        }

        $body = @{
            sourceRefName = "$($preferenced_branch.name)"
            targetRefName = "refs/heads/dev"
            title         = "$PR_title"
            description   = $workItem."System.Title"
            workItemRefs  = @(
                @{
                    id  = $workItem."System.id"
                    url = $workItem."System.id"
                }
            )
            reviewers     = $()
        }

        if (!$Quiet) {
            $body
        }

        $pull_request_id = Invoke-AzDevOpsRest -Method POST -body $body -CALL PROJ -Property "pullRequestId" -API "/_apis/git/repositories/$($preferenced_repo.id)/pullrequests" 

        $project_name = $preferenced_repo.project.name.replace(" ", "%20")
        $pull_request_url = "https://dev.azure.com/baugruppe/$project_name/_git/$($preferenced_repo.name)/pullrequest/$pull_request_id"

        Write-Host -Foreground Green "      "
        Write-Host -Foreground Green " 🎉 New Pull-Request created  🎉  "
        Write-Host -Foreground Green "    $pull_request_url "
        Write-Host -Foreground Green "      "

        Start-Process $pull_request_url

    } 
    catch {

        $_

    }

}
