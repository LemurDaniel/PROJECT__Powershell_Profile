


# Test - Abstract Query to get Create events on any resource  with some customization. back x-days.
function Get-AzResourceGraphChangesCreate {


    [CmdletBinding()]
    param (
        # The resourceType to filter change events from.
        [Parameter(Mandatory = $true)]
        [System.String]
        $resourceType,

        # The change attribute to capture
        [Parameter(Mandatory = $false)]
        [System.Collections.Hashtable]
        $resourceAttributes = @{
            diskSizeBytes = 'format_bytes(tolong(properties.diskSizeBytes))'
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
    $resourceAttributesExtensions = $resourceAttributes.Keys.Count -gt 0 ? ", $($resourceAttributes.Keys -join ',' )" : ''

    return Search-AzGraph -ManagementGroup $managementGroup -Query "
        resourcechanges
        | where properties.targetResourceType =~ '$resourceType' 
        // Get only Changes after Timestamp of Type Create.
        | where properties.changeType =~ 'Create'
        | where properties.changeAttributes.timestamp > datetime($TimeStamp)
        | extend Operation = properties.changeType
        // Get Basic Change Attributes.
        | extend TimeStamp = tostring(properties.changeAttributes.timestamp)
        | extend resourceId = tolower(tostring(properties.targetResourceId))
        | extend resourceName = split(resourceId,'/')[-1]
        // Check for existence of resource. (In case resource was deleted, then ignore Create Events.)
        | join kind=leftouter (
            resources 
            | where type =~ '$resourceType' 
            | extend id = tolower(id)
            | extend joinResExistent = true
            $(
                $resourceAttributes.GetEnumerator() | ForEach-Object { "| extend $($_.Key) = $($_.Value)`n" }
            )
        ) on `$left.resourceId == `$right.id
        | where isnotnull(joinResExistent)
        // Check for Deletion Events on the resource. (A Resource that was Deleted and a Creat Event can be interpreted as 'Recreate')
        | join kind=leftouter (
            resourcechanges 
            | where properties.targetResourceType =~ '$resourceType'  
            | where properties.changeAttributes.timestamp > datetime($TimeStamp)
            | where properties.changeType =~ 'Delete'
            | extend TimeStampDelete = todatetime(tostring(properties.changeAttributes.timestamp))
            | extend id = tolower(tostring(properties.targetResourceId))
            ) on `$left.resourceId == `$right.id
        // Summarize any number of events on the same resource Id into one.
        | summarize CollapsedEvents = 1 + count(TimeStamp), arg_max(TimeStamp, Operation, tenantId, subscriptionId, resourceGroup, resourceName, TimeStamp $resourceAttributesExtensions), arg_min(TimeStampDelete, id) by resourceId
        | extend Operation = iif(todatetime(TimeStamp) > TimeStampDelete, 'Recreate', Operation)
        | extend resourceURL = strcat('https://portal.azure.com/#@', tenantId, '/resource/', resourceId)
        | project Operation, CollapsedEvents, subscriptionId, resourceGroup, name = resourceName, TimeStamp, TimeStampDelete, resourceURL $resourceAttributesExtensions
        | sort by TimeStamp desc
        "
    
}

<#

Get-AzResourceGraphChangesCreate -resourceType 'microsoft.compute/disks' `
    -resourceAttributes @{
    diskSizeBytes = 'format_bytes(tolong(properties.diskSizeBytes))'
}

Get-AzResourceGraphChangesCreate -resourceType 'microsoft.compute/virtualmachines' `
    -resourceAttributes @{
    vmSize = "properties.hardwareProfile.vmSize"
}

#>
