<#
    .SYNOPSIS
    Gets Create Events of a resource type from the Azure Resource Graph.

    .DESCRIPTION
    Gets Create Events of a resource type from the Azure Resource Graph,
    while filtering out deleted resources and designated delted and created resources as recreated.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Return the result of the Az Resource Graph Query.


    
    .EXAMPLE

    Get all newly created Virtual Machines in the last 7-Days with their sizes and tags:

    # This is useful for example for Azure-Reservations that can then be done based on Creations of new VMs with their VmSizes.

    PS> Get-AzResourceGraphChangesCreate -ResourceType 'microsoft.compute/virtualmachines' `
            -ResourceAttributes @{
                vmSize              = 'properties.hardwareProfile.vmSize'
                acfVmOperatingHours = 'tags.acfVmOperatingHours'
            }


    .EXAMPLE

    Get all newly created Disks in the last 3-Days with their sku and disksize in bytes:

    PS> Get-AzResourceGraphChangesCreate -ResourceType 'microsoft.compute/disks' `
            -TimeStamp ([DateTime]::Now.AddDays(-3)) `
            -ResourceAttributes @{
                diskSizeBytes     = 'format_bytes(tolong(properties.diskSizeBytes))'
                skuName           = 'sku.name'
                skuTier           = 'sku.tier'
            }


    .EXAMPLE

    Get the general Properties and tags of any 'microsoft.compute' resource created in the last 4-Days:

    PS> Get-AzResourceGraphChangesCreate 'startswith' 'microsoft.compute' `
            -TimeStamp ([DateTime]::Now.AddDays(-4)) `
            -ResourceAttributes @{
                properites          = 'properties'
                tags                = 'tags'
            }


    .EXAMPLE

    Get the general Properties and tags of any 'microsoft.compute/disks' and 'microsoft.compute/virtualmachines' resource created in the last 4-Days:

    PS> Get-AzResourceGraphChangesCreate 'in~' 'microsoft.compute/disks', 'microsoft.compute/virtualmachines' `
            -TimeStamp ([DateTime]::Now.AddDays(-4)) `
            -ResourceAttributes @{
                properites          = 'properties'
                tags                = 'tags'
            }


    .EXAMPLE

    Filter out change events on 'microsoft.compute' resources where a regex filters out target-resource-ids with Sandbox Resource Groups:

    PS> Get-AzResourceGraphChangesCreate 'startswith' 'microsoft.compute' `
            -regexMatchId 'resourcegroups/rg-[MPmp0-9]+sandbox-dev-001' `
            -ResourceAttributes @{
                properites          = 'properties'
                tags                = 'tags'
            }

    .LINK
        
#>

function Get-AzResourceGraphChangesCreate {


    [CmdletBinding()]
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

        # The ResourceType to filter change events for.
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

        # Any additional Resource attributes to be returned from the changed resource.
        [Parameter(Mandatory = $false)]
        [System.Collections.Hashtable]
        $ResourceAttributes = @{},

        # The Timestamp from back when to take the change events.
        [Parameter(Mandatory = $false)]
        #[ValidateScript(
        #    {
        #        # Resource Graph changes apperently only date back to the last 7 days.
        #        $_ -ge ([DateTime]::Now.AddDays(-7).AddMinutes(-1))
        #    },
        #    ErrorMessage = 'Timestampe is out of Range.' 
        #)]
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

    $TimeStamp = $TimeStamp ? $TimeStamp : [DateTime]::Now.AddDays(-7)
    $TimeStampEnd = $TimeStampEnd ? $TimeStampEnd : [DateTime]::Now.AddDays(1)

    $managementGroup = [System.String]::IsNullOrEmpty($managementGroup) ? (Get-AzContext).Tenant.Id : $managementGroup
    $ResourceAttributesExtensions = $ResourceAttributes.Keys.Count -gt 0 ? ", $($ResourceAttributes.Keys -join ',' )" : ''

    $ResourceType = $ResourceType | ForEach-Object { "'$_'" }
    $ResourceTypeQuery = $ResourceType.Count -eq 1 ? $($ResourceType[0]) : "($($ResourceType -join ', '))" 

    return Search-AzGraph -ManagementGroup $managementGroup -Query "
        resourcechanges
        | where properties.targetResourceType $ResourceTypeFilter $ResourceTypeQuery
        // Get only Changes after Timestamp of Type Create.
        | where properties.changeType =~ 'Create'
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
        // This is to prevent failures with the Resource Attributes. (Since change attributes also have tags => the join on would become tags1 then | Adding Project to avoid the confusion)
        | project Operation, targetResourceType, subscriptionId, resourceGroup, resourceName, TimeStamp, resourceId
        // Check for existence of resource. (In case resource was deleted, then ignore Create Events.)
        | join kind=leftouter (
            resources 
            | where type $ResourceTypeFilter $ResourceTypeQuery
            | extend id = tolower(id)
            | extend joinResExistent = true
            $(
                $ResourceAttributes.GetEnumerator() | ForEach-Object { "| extend $($_.Key) = $($_.Value)`n" }
            )
        ) on `$left.resourceId == `$right.id
        // Checking if notnull, boolean is irrelevant. Any non-matches will have a null value.
        | where isnotnull(joinResExistent)
        // Check for Deletion Events on the resource. (A Resource that was Deleted and a Creat Event can be interpreted as 'Recreate')
        | join kind=leftouter (
            resourcechanges 
            | where properties.targetResourceType $ResourceTypeFilter $ResourceTypeQuery 
            | where properties.changeAttributes.timestamp > datetime($TimeStamp)
            | where properties.changeAttributes.timestamp < datetime($TimeStampEnd)
            | where properties.changeType =~ 'Delete'
            | extend TimeStampDelete = todatetime(tostring(properties.changeAttributes.timestamp))
            | extend resourceId = tolower(tostring(properties.targetResourceId))
            ) on `$left.resourceId == `$right.resourceId
        // Summarize any number of events on the same resource Id into one.
        | summarize CollapsedEvents = 1 + count(TimeStamp), arg_max(TimeStamp, Operation, targetResourceType, tenantId, subscriptionId, resourceGroup, resourceName, TimeStamp $ResourceAttributesExtensions), arg_min(TimeStampDelete, id) by resourceId
        | extend Operation = iif(todatetime(TimeStamp) > TimeStampDelete, 'Recreate', Operation)
        | extend resourceURL = strcat('https://portal.azure.com/#@', tenantId, '/resource', resourceId)
        | project Operation, CollapsedEvents, targetResourceType, tenantId, subscriptionId, resourceGroup, name = resourceName, TimeStamp, TimeStampDelete, resourceId, resourceURL $ResourceAttributesExtensions
        | sort by TimeStamp desc
        "
    
}