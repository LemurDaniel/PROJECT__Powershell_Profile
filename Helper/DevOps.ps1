

function Update-AzDevOpsSecrets {

    $DEVOPS = Get-PersonalSecret -SecretType AZURE_DEVOPS
    $EXPIRES = [System.DateTime] $DEVOPS.EXPIRES
    $TIMESPAN = New-TimeSpan -Start ([System.DateTime]::now) -End $EXPIRES
    if ($TIMESPAN.Days -lt 2) {
        Load-ONEDRIVE_SecretStore
    }
    
}

function Invoke-AzDevOpsRest {

    param(
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("GET", "POST", "PUT", "UPDATE", "DELETE")]
        $Method,

        [Parameter()]
        [System.String]
        [ValidateSet("dev", "vssps", "vsaex.dev")]
        $Type = "dev",

        [Parameter()]
        [System.String]
        $API,

        [Parameter()]
        [System.String]
        $API_Project,

        [Parameter()]
        [System.String]
        $API_Team,

        [Parameter()]
        [System.String]
        $URI,

        [Parameter()]
        [System.Collections.Hashtable]
        $body = @{},

        [Parameter()]
        [System.String]
        $Property = "value",

        [Parameter()]
        [System.String]
        [ValidateSet([RepoProjects])] # DC-Migration, RD-Redeployment
        $Project = "DC",

        [Parameter()]
        [System.Boolean]
        $Quiet = [System.Boolean]::parse($env:QUIET)
    )

    $ProjectName = "DC%20Azure%20Migration"
    $Team = "DC%20Azure%20Migration%20Team"
    if ($Project -eq "RD") {
        $ProjectName = "DC%20ACF%20Redeployment"
        $Team = ""
    }
    elseif ($Project -eq "DCProjects") {
        $ProjectName = "DCProjects"
        $Team = ""
    } 
    elseif ($Project -eq "TB") {
        $ProjectName = "TeamsBuilder"
        $Team = ""
    } 
    $TargetUri = "https:///$(Join-Path -Path "$Type.azure.com/baugruppe/" -ChildPath $API)".Replace("\", "/").Replace("//", "/")
    if ($API_Project) {
        $TargetUri = "https:///$(Join-Path -Path "$Type.azure.com/baugruppe/$ProjectName/" -ChildPath $API_Project)".Replace("\", "/").Replace("//", "/")
    }
    elseif ($API_Team) {
        $TargetUri = "https:///$(Join-Path -Path "$Type.azure.com/baugruppe/$ProjectName/$Team/" -ChildPath $API_Team)".Replace("\", "/").Replace("//", "/")
    }
    elseif ($URI) {
        $TargetUri = $URI
    }


    if (!$TargetUri.contains("api-version")) {
        if ($TargetUri.contains("?")) {
            $TargetUri += "&api-version=7.1-preview.1"
        }
        else {
            $TargetUri += "?api-version=7.1-preview.1"
            $TargetUri = $TargetUri.Replace("/?", "?")
        }
    }

    Write-Host "    "$TargetUri

    try {
        $headers = @{ 
            username       = "my-user-name"
            password       = "Basic $env:AZURE_DEVOPS_HEADER"
            Authorization  = "Basic $env:AZURE_DEVOPS_HEADER"
            "Content-Type" = $Method.ToLower() -eq "get" ? "application/x-www-form-urlencoded" : "application/json"
        }

        $response = ""
        if ($Quiet) {
            $response = Invoke-RestMethod -Method $Method -Uri $TargetUri -Headers $headers -Body ($body | ConvertTo-Json -Compress)
        }
        else {
            $response = Invoke-RestMethod -Method $Method -Uri $TargetUri -Headers $headers -Body ($body | ConvertTo-Json -Compress) -Verbose
        }

        if ($Property) {
            $response = ($response.PSObject.Properties | Where-Object { $_.Name -like $Property }).Value 
        }

        return [array]@($response)
        

        #####
        Write-Host ($response -is [array])
        if ( !($response -is [array]) ) {
            
            Write-Host "Return Array"
            return @($response)
        }
        else {
            Write-Host "Return Response"
            return $response
        }

    }
    catch {
        Write-Host "ERROR"
        throw $_
    }
   
}
#Invoke-AzDevOpsRest -Method Get -Type vssps -API /_apis/tokens

function New-BranchFromWorkitem {

    [Alias("gitW")]
    param (
        [Parameter()]
        [System.String[]]
        $SearchTags
    )
    
    $currentIteration = Invoke-AzDevOpsRest -Method GET -API_Team "/_apis/work/teamsettings/iterations?`$timeframe=current&api-version=7.1-preview.1"
    $workItems = Invoke-AzDevOpsRest -Method GET -Property "WorkItemRelations" -API_Team "/_apis/work/teamsettings/iterations/$($currentIteration.Id)/workitems?api-version=7.1-preview.1"

    $body = @{
        ids    = $workItems.target.id
        fields = @(
            "System.Id",
            "System.Title",
            "System.AssignedTo",
            "System.WorkItemType",
            "Microsoft.VSTS.Scheduling.RemainingWork"
        )
    }

    $workItems = (Invoke-AzDevOpsRest -Method POST -API_Project "/_apis/wit/workitemsbatch?api-version=7.1-preview.1" -body $body).fields | Where-Object { $_.'System.AssignedTo'.uniqueName -like "daniel.landau@brz.eu" }

    $workItem = Get-PreferencedObject -SearchObjects $workItems -SearchTags $SearchTags -SearchProperty "System.Title"
    
    $isRepo = (Get-ChildItem -Path . -Directory -Hidden -Filter '.git').Count -gt 0
    
    if (!$isRepo) {
        Write-Host "Please exexcute command inside a Repository"
    }
    elseif ($workItem) {


        $transformedTitle = $workItem.'System.Title'.toLower().replace(':', '_').replace('!', '').replace('?', '').split(' ') -join '-'

        $branchName = "features/$($workItem.'System.id')-$transformedTitle"

        $byteArray = [System.BitConverter]::GetBytes((Get-Random))
        $hex = [System.Convert]::ToHexString($byteArray)
        git stash save "st-$hex"
        git checkout master
        git pull origin master
        git checkout dev
        git pull origin dev
        git checkout -b "$branchName"
        git stash pop
    }

}


function New-MasterPR {

    param(
        [Parameter()]
        [System.String]
        $PR_title = "Merge DEV into MASTER",

        [Parameter()]
        [System.Boolean]
        $Approve = $false
    )

    try {

        # Get Repo name
        $search_by_key = "remoteUrl"
        $repository_name = "terraform-acf-main" 
        try {
            $repository_name = (git rev-parse --show-toplevel).split('/')[-1]
        }
        catch {

        }
    
        # Search by remote url
        $repository_list = Invoke-AzDevOpsRest -Method GET -API_Project "/_apis/git/repositories"
        $preferenced_repo = Get-PreferencedObject -SearchObjects $repository_list -SearchTags $repository_name -SearchProperty $search_by_key
        $repository_id = $preferenced_repo.id

        $active_pull_requests = Invoke-AzDevOpsRest -Method GET -API_Project "/_apis/git/repositories/$repository_id/pullrequests"
        $chosen_pull_request = $active_pull_requests | Where-Object { $_.targetRefName -eq "refs/heads/master" }

        if (!$chosen_pull_request) {

            $body = @{
                sourceRefName = "refs/heads/dev"
                targetRefName = "refs/heads/master"
                title         = "Merge branch DEV into Master"
                description   = ""
                reviewers     = $(
                    #{
                    #  "id": "d6245f20-2af8-44f4-9451-8107cb2767db"
                    #}
                )
            }
        
            $chosen_pull_request = Invoke-AzDevOpsRest -Method POST -body $body -Property $null -API_Project "/_apis/git/repositories/$repository_id/pullrequests" 

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
        $PR_title = $null
    )

    try {

        # Get Repo name
        $search_by_key = "remoteUrl"
        $repository_name = (git rev-parse --show-toplevel).split('/')[-1]

        # Search by remote url
        $repository_list = Invoke-AzDevOpsRest -Method GET -API_Project "/_apis/git/repositories"
        $preferenced_repo = Get-PreferencedObject -SearchObjects $repository_list -SearchTags $repository_name -SearchProperty $search_by_key
        $repository_id = $preferenced_repo.id

        # Search branch by name
        $current_branch = git branch --show-current
        $remote_branches = Invoke-AzDevOpsRest -Method GET -API_Project "/_apis/git/repositories/$repository_id/refs"
        $preferenced_branch = Get-PreferencedObject -SearchObjects $remote_branches -SearchTags $current_branch


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
            description   = ""
            reviewers     = $(
                #{
                #  "id": "d6245f20-2af8-44f4-9451-8107cb2767db"
                #}
            )
        }

        if (!$Quiet) {
            $body
        }

        $pull_request_id = Invoke-AzDevOpsRest -Method POST -body $body -Property "pullRequestId" -API_Project "/_apis/git/repositories/$repository_id/pullrequests" 

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
