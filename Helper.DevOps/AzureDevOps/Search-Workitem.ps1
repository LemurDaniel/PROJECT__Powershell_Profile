function Search-WorkItem {
    param(
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $SearchTags,

        [Parameter()]
        [switch]
        $Personal,

        [Parameter()]
        [switch]
        $Single
    )

    $Request = @{
        Method = 'GET'
        SCOPE  = 'PROJ'
        API    = "/_apis/work/teamsettings/iterations?`$timeframe=current&api-version=7.0"
    }
    $currentIteration = Invoke-DevOpsRest @Request

    $Request = @{
        Method = 'GET'
        SCOPE  = 'PROJ'
        API    = "/_apis/work/teamsettings/iterations/$($currentIteration.value.id)/workitems?api-version=7.1-preview.1"
    }
    $workItems = Invoke-DevOpsRest @Request

    $Request = @{
        Method = 'POST'
        SCOPE  = 'PROJ'
        API    = '/_apis/wit/workitemsbatch?api-version=7.1-preview.1'
        Body   = @{
            ids    = $workItems.WorkItemRelations.target.id
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

    $workItems = (Invoke-DevOpsRest @Request).value.fields
        
    if ($Personal) {
        $workItems = $workItems | Where-Object { $_.'System.AssignedTo'.uniqueName -like (Get-AzContext).Account.Id }
    }
    
    return Search-In $workItems -where 'System.Title' -is $SearchTags -Multiple:$(!$Single)
}
