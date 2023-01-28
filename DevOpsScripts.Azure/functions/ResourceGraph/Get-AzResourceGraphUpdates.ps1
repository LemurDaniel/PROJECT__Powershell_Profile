


# Test - Abstract Query to get change events on any resource  with some customization. back x-days.
function Get-AzResourceGraphUpdates {


    [CmdletBinding()]
    param (

        # The resourceType to filter change events from.
        [Parameter(Mandatory = $false)]
        [System.String]
        $resourceType = 'microsoft.compute/disks',

        # Any change attributes to capture on the change events.
        [Parameter(Mandatory = $false)]
        [System.Collections.Hashtable]
        $ChangeAttributes = @{
            # Gets inserted in this order, so keys can make references to previous keys.
            previousDiskSize      = "iff(isnull(properties.changes.['properties.diskSizeBytes'].previousValue), 0, properties.changes.['properties.diskSizeBytes'].previousValue)"
            newDiskSize           = "iff(isnull(properties.changes.['properties.diskSizeBytes'].newValue), 0, properties.changes.['properties.diskSizeBytes'].newValue)"
            previousDiskSizeBytes = 'format_bytes(tolong(previousDiskSize))'
            newDiskSizeBytes      = 'format_bytes(tolong(newDiskSize))'
        },

        # Any change attributes to capture on the change events.
        [Parameter(Mandatory = $false)]
        [System.Collections.Hashtable]
        $resourceAttributes = @{
            # Gets inserted in this order, so keys can make references to previous keys.
            diskSizeBytesResource = 'format_bytes(tolong(properties.diskSizeBytes))'
        },


        # The Timestamp from back when to take the change events.
        [Parameter(Mandatory = $false)]
        [ValidateScript(
            {
                # Resource Graph changes apperently only date back to the last 7 days.
                $_ -ge ([DateTime]::Now.AddDays(-7).AddMinutes(1))
            },
            ErrorMessage = 'Timestampe is out of Range.' 
        )]
        [System.DateTime]
        $TimeStamp = [System.DateTime]::Now.AddDays(-7)
    
    )

    $managementGroup = (Get-AzContext).Tenant.Id

    $ChangeAttributes = @{}
    $resourceAttributes = @{}
    if (($changeAttributes.Keys.Count + $resourceAttributes.Keys.Count) -gt 0) {
        $attributeExtensions = ($changeAttributes.Keys + $resourceAttributes.Keys) -join ', '
    }
    # Search-AzGraph -ManagementGroup $managementGroup -Query
    #$changeAttributesExtensions = $changeAttributes.Keys.Count -gt 0 ? ", $($changeAttributes.Keys -join ',' )" : ''
    #$resourceAttributesExtensions = $resourceAttributes.Keys.Count -gt 0 ? ", $($resourceAttributes.Keys -join ',' )" : ''
    return  Search-AzGraph -ManagementGroup $managementGroup -Query "
        resourcechanges
        | where properties.targetResourceType =~ '$resourceType' 
        // Get only Changes after Timestamp of Type Update.
        | where properties.changeType =~ 'Update'
        | where properties.changeAttributes.timestamp > datetime($TimeStamp)
        | extend Operation = properties.changeType
        // Get Basic Change Attributes.
        | extend TimeStamp = tostring(properties.changeAttributes.timestamp)
        | extend resourceId = tolower(tostring(properties.targetResourceId))
        | extend resourceName = split(resourceId,'/')[-1]
        // Check for existence of resource. (In case resource was deleted, then ignore update events.)
        | join kind=leftouter (
            resources 
            | where type =~ '$resourceType' 
            | extend id = tolower(id)
            | extend joinResExistent = true
            $(
                $resourceAttributes.GetEnumerator() | ForEach-Object { "| extend $($_.Key) = $($_.Value)" }
            )
        ) on `$left.resourceId == `$right.id
        | where isnotnull(joinResExistent)
        // Check for Creation Events on the resource. (Maybe make it optional, as of now create events will be handled seperatly and not included in change events.)
        | join kind=leftouter (
            resourcechanges 
            | where properties.targetResourceType =~ '$resourceType' 
            | where properties.changeAttributes.timestamp > datetime($TimeStamp)
            | where properties.changeType =~ 'Create'
            | extend WasCreated = true
            | extend resourceId = tolower(tostring(properties.targetResourceId))
        ) on `$left.resourceId == `$right.resourceId
        // Summarize any number of events on the same resource Id into one.
        | summarize CollapsedEvents = count(TimeStamp), arg_max(TimeStamp, *), arg_min(MinTimeStamp = TimeStamp, id) by resourceId
        | where isnull(WasCreated)
        $(
            $ChangeAttributes.GetEnumerator() | ForEach-Object { "| extend $($_.Key) = $($_.Value)`n" }
        )
        | extend resourceURL = strcat('https://portal.azure.com/#@', tenantId, '/resource/', resourceId)
        | project Operation, CollapsedEvents, subscriptionId, resourceGroup, name = resourceName, TimeStamp, MinTimeStamp, resourceURL $attributeExtensions
        | sort by TimeStamp desc
        "
    
}
