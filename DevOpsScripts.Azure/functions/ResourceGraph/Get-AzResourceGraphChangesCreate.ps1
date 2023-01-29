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

    Get all newly created Virtual Machines in the last 3-Days with their sizes and tags:

    PS> Get-AzResourceGraphChangesCreate -ResourceType 'microsoft.compute/virtualmachines' `
            -ResourceAttributes @{
                vmSize              = 'properties.hardwareProfile.vmSize'
                acfVmOperatingHours = 'tags.acfVmOperatingHours'
            }


    .EXAMPLE

    Get all newly created Disks in the last 7-Days with their sku and disksize in bytes:

    PS> Get-AzResourceGraphChangesCreate -ResourceType 'microsoft.compute/disks' `
            -TimeStamp ([DateTime]::Now.AddDays(-3)) `
            -ResourceAttributes @{
                diskSizeBytes     = 'format_bytes(tolong(properties.diskSizeBytes))'
                skuName           = 'sku.name'
                skuTier           = 'sku.tier'
            }


    .LINK
        
#>

function Get-AzResourceGraphChangesCreate {


    [CmdletBinding()]
    param (
        # The ResourceType to filter change events from.
        [Parameter(Mandatory = $true)]
        [System.String]
        $ResourceType,

        # The change attribute to capture
        [Parameter(Mandatory = $false)]
        [System.Collections.Hashtable]
        $ResourceAttributes = @{
            diskSizeBytes = 'format_bytes(tolong(properties.diskSizeBytes))'
        },

        # The Timestamp from back when to take the change events.
        [Parameter(Mandatory = $false)]
        [ValidateScript(
            {
                # Resource Graph changes apperently only date back to the last 7 days.
                $_ -ge ([DateTime]::Now.AddDays(-7).AddMinutes(-1))
            },
            ErrorMessage = 'Timestampe is out of Range.' 
        )]
        [System.DateTime]
        $TimeStamp = [System.DateTime]::Now.AddDays(-7),

        # Mangement Group Scope on which to perform query. Will default to tennand id.
        [Parameter(Mandatory = $false)]
        [System.String]
        $managementGroup
    )

    $managementGroup = [System.String]::IsNullOrEmpty($managementGroup) ? (Get-AzContext).Tenant.Id : $managementGroup
    $ResourceAttributesExtensions = $ResourceAttributes.Keys.Count -gt 0 ? ", $($ResourceAttributes.Keys -join ',' )" : ''

    return Search-AzGraph -ManagementGroup $managementGroup -Query "
        resourcechanges
        | where properties.targetResourceType =~ '$ResourceType' 
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
            | where type =~ '$ResourceType' 
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
            | where properties.targetResourceType =~ '$ResourceType'  
            | where properties.changeAttributes.timestamp > datetime($TimeStamp)
            | where properties.changeType =~ 'Delete'
            | extend TimeStampDelete = todatetime(tostring(properties.changeAttributes.timestamp))
            | extend resourceId = tolower(tostring(properties.targetResourceId))
            ) on `$left.resourceId == `$right.resourceId
        // Summarize any number of events on the same resource Id into one.
        | summarize CollapsedEvents = 1 + count(TimeStamp), arg_max(TimeStamp, Operation, tenantId, subscriptionId, resourceGroup, resourceName, TimeStamp $ResourceAttributesExtensions), arg_min(TimeStampDelete, id) by resourceId
        | extend Operation = iif(todatetime(TimeStamp) > TimeStampDelete, 'Recreate', Operation)
        | extend resourceURL = strcat('https://portal.azure.com/#@', tenantId, '/resource', resourceId)
        | project Operation, CollapsedEvents, subscriptionId, resourceGroup, name = resourceName, TimeStamp, TimeStampDelete, resourceURL $ResourceAttributesExtensions
        | sort by TimeStamp desc
        "
    
}