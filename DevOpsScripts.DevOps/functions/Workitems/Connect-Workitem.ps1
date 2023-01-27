<#
    .SYNOPSIS
    Creates a workitem  Relation between to workitems.

    .DESCRIPTION
    Creates a workitem  Relation between to workitems.

    .INPUTS
    None. You cannot pipe objects into Connect-Workitem

    .OUTPUTS
    The API-Respone with the first provided workitem and the new relation field.

    .EXAMPLE

    Create a Child Relation to a UserStory

    PS> $userStory = New-Workitem -Type 'User Story' -Title 'APITEST_UserStory'
    PS> $task = New-Workitem -Type Task -Title 'APITEST_Task'
    PS> Connect-Workitem -WorkItem1 $userStory -WorkItem2 $task -RelationType Child


    .LINK
        
#>

function Connect-Workitem {

    param(
        # Workitem for Relation
        [Parameter(
            Mandatory = $true
        )]
        [PSCustomObject[]] # TODO, Provide class
        $WorkItem1,

        # Workitem for Relation
        [Parameter(
            Mandatory = $true
        )]
        [PSCustomObject[]]
        $WorkItem2,

        # Workitem Relation Type => Parent, Child, etc.
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $RelationType
    )

    $Request = @{
        METHOD      = 'PATCH'
        DOMAIN      = 'dev.azure'
        CALL        = 'PROJ'
        API         = "_apis/wit/workitems/$($WorkItem1.id)?api-version=7.0"
        ContentType = 'application/json-patch+json'
        Body        = @(
            @{
                op    = 'add'
                path  = '/relations/-'
                value = @{
                    rel        = Get-WorkItemRelationType $RelationType -return 'referenceName'
                    url        = $WorkItem2.url
                    attributes = @{
                        comment = "$((Get-CurrentUser).displayName) created $RelationType on workitem $($WorkItem1.name) to $($WorkItem2.name)"
                    }
                }
            }
        )
        AsArray     = $true
    }

    return Invoke-DevOpsRest @Request
}
