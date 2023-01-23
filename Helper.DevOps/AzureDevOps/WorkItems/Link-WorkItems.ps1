<#
    .SYNOPSIS
    Creates a workitem with several fields.

    .DESCRIPTION
    Creates a worktime of a specific type, with several field an an optional parent.

    .INPUTS
    None. You cannot pipe objects into New-Workitem

    .OUTPUTS
    System.PSCustomObject A single created workitem.

    .EXAMPLE

    Create a User Story with a Title:

    PS> New-Workitem -Type 'User Story' -Title 'Document Powershell Module'

    .EXAMPLE

    Create a Task with a Title and a Parent Workitem:

    PS> New-Workitem -Type Task -Title 'Document Powershell Module' -ParentId 12034


    .LINK
        
#>

function New-Workitem {

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
        [PSCustomObject[]]
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
                        comment = 'Making a new link for the dependency'
                    }
                }
            }
        )
        AsArray     = $true
    }

    return Invoke-DevOpsRest @Request
}
