
<#
    .SYNOPSIS
    Gets Delete Events of a resource type from the Azure Resource Graph.

    .DESCRIPTION
    Gets Delete Events of a resource type from the Azure Resource Graph with one specific update property,
    filtering out resources that were created again and still exist, also designating Created and Deleted Resources as 'CreateAndDelete' with a Time Lived in Hours.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Return the result of the Az Resource Graph Query.


    
    .EXAMPLE

    Get all Deletion Events in the last 7-Days for Virtual Machines:

    PS> Get-AzResourceGraphChangesDelete -ResourceType 'microsoft.compute/virtualmachines'


    .EXAMPLE

    Get all Deletion Events in the last 3-Days for Disks:

    PS> Get-AzResourceGraphChangesDelete -ResourceType 'microsoft.compute/disks' -TimeStamp ([DateTime]::Now.AddDays(-3))


    .EXAMPLE

    Get all Deletion Events in the last 3-Days for Disks and virtual machines:

    PS> Get-AzResourceGraphChangesDelete 'in~' 'microsoft.compute/virtualmachines', 'microsoft.compute/disks' -TimeStamp ([DateTime]::Now.AddDays(-3))


    .EXAMPLE

    Get all Deletion Events on 'microsoft.compute' resources with a regex match on ids with Sandbox Resource Groups:

    PS> Get-AzResourceGraphChangesDelete 'startswith' 'microsoft.compute' `
            -regexMatchId 'resourcegroups/rg-[MPmp0-9]+sandbox-dev-001'

    .LINK
        
#>

function Get-AzResourceGraphChangesDelete {


    [CmdletBinding()]
    [OutputType([System.Array])]
    param (
        # A resource type filter to allow for more customization. Default ist '=~' Equals-CaseInsensitive
        [Parameter(
            Position = 0,
            Mandatory = $false
        )]
        [ValidateSet(
            '==', #Case-Sensitive
            '=~', #Case-InSensitive
            '!=', #Case-Sensitive
            '!~', #Case-InSensitive
            'contains', #Case-InSensitive
            '!contains', #Case-InSensitive
            'endswith', #Case-InSensitive
            '!endwith', #Case-InSensitive
            'startswith', #Case-InSensitive
            '!startswith', #Case-InSensitive
            'matches regex',
            'in~', #Case-InSensitive
            '!in~' #Case-InSensitive
        )]
        [System.String]
        $ResourceTypeFilter = '=~',

        # The ResourceType to filter change events from.
        [Parameter(
            Position = 1,
            Mandatory = $true
        )]
        [System.String[]]
        $ResourceType,

        # Additional Filter to filter out resources that start with a certain name.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $NameStartsWith = '',

        # Additional Filter to filter out resources that Contain a ceratin string in their name.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $NameContains = '',

        # Additional Filter to filter out resources that Contain a ceratin string in their resourceGroup.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $regexMatchId = '',


        # The Timestamp from back when to take the change events.
        [Parameter(Mandatory = $false)]
        [System.DateTime]
        $TimeStamp,

        # An additional Timestamp to create a range to search in. From for Example last 24-Hours until up to last 12-Hours.
        [Parameter(Mandatory = $false)]
        [ValidateScript(
            {
                # Resource Graph changes apperently only date back to the last 7 days.
                $_ -ge ([DateTime]::Now.AddDays(-7).AddMinutes(-1))
            },
            ErrorMessage = 'Timestampe is out of Range.' 
        )]
        [System.DateTime]
        $TimeStampEnd,

        # Mangement Group Scope on which to perform query. Will default to tennand id.
        [Parameter(Mandatory = $false)]
        [System.String]
        $managementGroup
    )
    
    $managementGroup = [System.String]::IsNullOrEmpty($managementGroup) ? (Get-AzContext).Tenant.Id : $managementGroup

    $TimeStamp = $TimeStamp ? $TimeStamp : [DateTime]::Now.AddDays(-7)
    $TimeStampEnd = $TimeStampEnd ? $TimeStampEnd : [DateTime]::Now.AddDays(1)

    $ResourceType = $ResourceType | ForEach-Object { "'$_'" }
    $ResourceTypeQuery = $ResourceType.Count -eq 1 ? $($ResourceType[0]) : "($($ResourceType -join ', '))" 

    return Search-AzResourceGraphResults -ManagementGroup $managementGroup -Query "
        resourcechanges
        | where properties.targetResourceType $ResourceTypeFilter $ResourceTypeQuery
        // Get only Changes after Timestamp of Type Delete.
        | where properties.changeType =~ 'Delete'
        | where properties.changeAttributes.timestamp > datetime($TimeStamp)
        | where properties.changeAttributes.timestamp < datetime($TimeStampEnd)
        | extend Operation = properties.changeType
        // Get Basic Change Attributes.
        | extend targetResourceType = properties.targetResourceType
        | extend TimeStamp = tostring(properties.changeAttributes.timestamp)
        | extend resourceId = tolower(tostring(properties.targetResourceId))
        $([System.String]::IsNullOrEmpty($regexMatchId)     ? ' ' : "| where resourceId matches regex '$regexMatchId'" )
        | extend resourceName = split(resourceId,'/')[-1]
        $([System.String]::IsNullOrEmpty($NameStartsWith)   ? ' ' : "| where resourceName startswith '$NameStartsWith'" )
        $([System.String]::IsNullOrEmpty($NameContains)     ? ' ' : "| where resourceName contains '$NameContains'" )

        // Filter out Resources that where created afterwards again and still exist.
        | join kind=leftouter (
            resources 
            | where type $ResourceTypeFilter $ResourceTypeQuery 
            | extend id = tolower(id)
            | extend joinResExistent = true
        ) on `$left.resourceId == `$right.id
        // Checking if null, boolean is irrelevant. Any non-matches will have a null value.
        | where isnull(joinResExistent)
        | join kind=leftouter (
            resourcechanges 
            | where properties.targetResourceType $ResourceTypeFilter $ResourceTypeQuery 
            | where properties.changeAttributes.timestamp > datetime($TimeStamp)
            | where properties.changeAttributes.timestamp < datetime($TimeStampEnd)
            | where properties.changeType =~ 'Create' 
            | project CreationEvent = properties
            | extend resourceId = tolower(tostring(CreationEvent.targetResourceId))
            | extend TimeStampCreate = todatetime(CreationEvent.changeAttributes.timestamp)
            ) on `$left.resourceId == `$right.resourceId
        // Summarize any number of events on the same resource Id into one.
        | summarize CollapsedEvents =  1 + count(TimeStamp), arg_max(TimeStamp, *), arg_min(TimeStampCreate, id) by resourceId
        // If a Vm was created before deletion, it is a CreateAndDelete and has a timelived.
        | extend Operation = iif(todatetime(TimeStamp) > TimeStampCreate, 'CreateAndDelete', Operation)
        | extend TimeLived = format_timespan(todatetime(TimeStamp) - TimeStampCreate, 'd:HH:mm')
        // Not of much use, since its deleted.
        | extend resourceURL = strcat('https://portal.azure.com/#@', tenantId, '/resource', resourceId)
        | project Operation, CollapsedEvents, targetResourceType, tenantId, subscriptionId, resourceGroup, name = resourceName, TimeStamp, TimeStampCreate, TimeLived, resourceId, resourceURL
        | sort by TimeStamp
        "
    
}