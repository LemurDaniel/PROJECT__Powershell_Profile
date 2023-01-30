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

    PS> $userStory = New-Workitem -Type 'User Story' -Title 'Document Powershell Module'
    PS> New-Workitem -Type Task -Title 'Document Powershell Module' -ParentId $userStory.id


    .LINK
        
#>

function New-Workitem {

    [CmdletBinding()]
    param(
        # Type of the new workitem.
        [Parameter(
            Position = 0
        )]
        [ValidateSet(
            'Epic',
            'Feature',
            'User Story',
            'Task',
            'Bug',
            'Issue'
        )]
        [System.String]
        $Type = 'User Story',

        # Title of the new Workitem
        [parameter(Mandatory = $true)]
        [System.String]
        $Title,

        # Description of the new Workitem.
        [Parameter()]
        [System.String]
        $Description = $null,

        # Team association.
        [Parameter()]
        $Team = 'DC Azure Migration',
        [System.String]

        [Parameter()]
        [System.String]
        $AreaPath = 'DC Azure Migration',


        # Optional Parent of newly created workitem.
        [Parameter()]
        [System.String]
        $ParentId,

        # Optional Parent of newly created workitem.
        [Parameter()]
        [System.String]
        $ParentUrl
    )



    $Request = @{
        Method = 'POST'
        SCOPE  = 'PROJ'
        API    = "/_apis/wit/workitems/`$${Type}?api-version=7.0"
        Body   = @(
            @{
                op    = 'add'
                path  = '/fields/System.Title'
                from  = $null
                value = $Title
            },
            @{
                op    = 'add'
                path  = '/fields/System.TeamProject'
                from  = $null
                value = $Team
            },
            @{
                op    = 'add'
                path  = '/fields/System.AreaPath'
                from  = $null
                value = $AreaPath
            },
            @{
                op    = 'add'
                path  = '/fields/System.Description'
                from  = $null
                value = $Description
            }
        )
    }

    if ($ParentId -OR $ParentUrl) {
        $Request.Body += @{
            op    = 'add'
            path  = '/relations/-'
            value = @{
                rel        = Get-WorkItemRelationTypes Parent -return referenceName
                url        = [System.String]::IsNullOrEmpty($ParentUrl) ? (Get-WorkItems -Ids $ParentId -return 'url') : $ParentUrl
                attributes = @{}
            }
        }
    }

    return Invoke-DevOpsRest @Request -ContentType 'application/json-patch+json'
}