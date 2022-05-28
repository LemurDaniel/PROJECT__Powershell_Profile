(Get-Content -Path $env:SECRET_TOKEN_STORE | ConvertFrom-Json).PSObject.Properties | `
    ForEach-Object { 
    Write-Host "Loading '$($_.Name)' from Secret Store"
    if ($_.value[0] -eq '´') {
        $value = Invoke-Expression -Command $_.value.substring(1)
        $null = New-Item -Path "env:$($_.Name)" -Value $value -Force
    }
    else {
        $null = New-Item -Path "env:$($_.Name)" -Value $_.Value -Force  
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
        [ValidateSet("DC", "RD")] # DC-Migration, RD-Redeployment
        $Project = "DC"
    )

    $ProjectName = "DC%20Azure%20Migration"
    $Team = "DC%20Azure%20Migration%20Team"
    if ($Project -eq "RD") {
        $ProjectName = "DC%20ACF%20Redeployment"
        $Team = ""
    }

    $TargetUri = "https://$(Join-Path -Path "dev.azure.com/baugruppe/$ProjectName/" -ChildPath $API_Project)".Replace("\", "/")
    if ($API_Team) {
        $TargetUri = "https://$(Join-Path -Path "dev.azure.com/baugruppe/$ProjectName/$Team/" -ChildPath $API_Team)".Replace("\", "/")
    }
    elseif ($URI) {
        $TargetUri = $URI
    }

    Write-Host "    "$TargetUri

    try {
        $headers = @{ 
            Authorization  = "Basic $env:AzureDevops_HEADER"
            "Content-Type" = $Method.ToLower() -eq "get" ? "application/x-www-form-urlencoded" : "application/json"
        }

        $response = Invoke-RestMethod -Method $Method -Uri $TargetUri -Headers $headers -Body ($body | ConvertTo-Json -Compress)

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


function New-BranchFromWorkitem {

    [Alias("gitW")]
    param (
        [Parameter()]
        [System.Collections.ArrayList]
        $SearchTags = [System.Collections.ArrayList]::new()
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


        $transformedTitle = $workItem.'System.Title'.toLower().replace(':','_').replace('!','').replace('?','').split(' ') -join '-'

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