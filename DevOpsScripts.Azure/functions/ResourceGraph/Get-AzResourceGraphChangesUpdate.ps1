<#
    .SYNOPSIS
    Gets Update Events of a resource type from the Azure Resource Graph.

    .DESCRIPTION
    Gets Update Events of a resource type from the Azure Resource Graph with one specific update property,
    filtering out create events, as well as deleted resources.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Return the result of the Az Resource Graph Query.


    .EXAMPLE

    Get all updates on Virtual Machine sizes with an additonal tag Attribute returned:
    retrieves the update property as: 'previousvmSize' and 'newvmSize'

    PS> Get-AzResourceGraphChangesUpdate -ResourceType 'microsoft.compute/virtualmachines' `
            -UpdateProperty 'hardwareProfile.vmSize' `
            -ResourceAttributes @{
                acfVmOperatingHours = 'tags.acfVmOperatingHours'
            }


    .EXAMPLE

    Get updates of disks on 'diskSizeBytes' formated as bytes with additional sku Attributes:

    PS> Get-AzResourceGraphChangesUpdate -ResourceType  'microsoft.compute/disks' `
            -UpdateProperty 'diskSizeBytes' -format 'format_bytes(tolong($1))' `
            -ResourceAttributes @{
                skuName           = 'sku.name'
                skuTier           = 'sku.tier'
            }

    .LINK
        
#>

function Get-AzResourceGraphChangesUpdate {


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
            'contains', #Case-Sensitive
            '!contains', #Case-InSensitive
            'endswith', #Case-Sensitive
            '!endwith', #Case-InSensitive
            'startswith', #Case-Sensitive
            '!startswith', #Case-InSensitive
            'matches regex' #Case-Sensitive
        )]
        [System.String]
        $ResourceTypeFilter = '=~',

        # The ResourceType to filter change events from.
        [Parameter(
            Position = 1,
            Mandatory = $true
        )]
        [System.String]
        $ResourceType,
        
        # The change attribute to capture
        [Parameter(Mandatory = $true)]
        [System.String]
        $UpdateProperty,
        
        # Any change attributes to capture on the change events.
        [Parameter(Mandatory = $false)]
        [System.String]
        $format = '$1',

        # The change attribute to capture
        [Parameter(Mandatory = $false)]
        [System.Collections.Hashtable]
        $ResourceAttributes = @{},

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
    $resourceExtensionAttributes = $ResourceAttributes.Keys.Count -gt 0 ? ", $($ResourceAttributes.Keys -join ', ')" : ''

    $propertyNameOld = "previous$($UpdateProperty.Split('.')[-1])"
    $propertyNameNew = "new$($UpdateProperty.Split('.')[-1])"
    return Search-AzGraph -ManagementGroup $managementGroup -Query "
        resourcechanges
        | where properties.targetResourceType $ResourceTypeFilter '$ResourceType' 
        // Get only Changes after Timestamp of Type Update.
        | where properties.changeType =~ 'Update'
        | where properties.changeAttributes.timestamp > datetime($TimeStamp)
        | where properties has 'properties.$UpdateProperty'
        | extend Operation = properties.changeType
        // Get Basic Change Attributes.
        | extend targetResourceType = properties.targetResourceType
        | extend TimeStamp = tostring(properties.changeAttributes.timestamp)
        | extend resourceId = tolower(tostring(properties.targetResourceId))
        | extend resourceName = split(resourceId,'/')[-1]
        | extend oldValue = properties.changes.['properties.$UpdateProperty'].previousValue
        | extend newValue = properties.changes.['properties.$UpdateProperty'].newValue
        | extend $propertyNameOld = $($format -replace '\$1', 'oldValue')
        | extend $propertyNameNew = $($format -replace '\$1', 'newValue')
        // This is to prevent failures with the Resource Attributes. (Since change attributes also have tags => the join on would become tags1 then | Adding Project to avoid the confusion)
        | project Operation, targetResourceType, subscriptionId, resourceGroup, resourceName, TimeStamp, resourceId, $propertyNameOld, $propertyNameNew
        // Check for existence of resource. (In case resource was deleted, then ignore update events.)
        | join kind=leftouter (
            resources 
            | where type $ResourceTypeFilter '$ResourceType' 
            | extend id = tolower(id)
            | extend joinResExistent = true
            $(
                $ResourceAttributes.GetEnumerator() | ForEach-Object { "| extend $($_.Key) = $($_.Value)" }
            )
        ) on `$left.resourceId == `$right.id
        // Checking if notnull, boolean is irrelevant. Any non-matches will have a null value.
        | where isnotnull(joinResExistent)
        // Check for Creation Events on the resource. (Maybe make it optional, as of now create events will be handled seperatly and not included in change events.)
        | join kind=leftouter (
            resourcechanges 
            | where properties.targetResourceType $ResourceTypeFilter '$ResourceType'
            | where properties.changeAttributes.timestamp > datetime($TimeStamp)
            | where properties.changeType =~ 'Create'
            | extend WasCreated = true
            | extend resourceId = tolower(tostring(properties.targetResourceId))
        ) on `$left.resourceId == `$right.resourceId
        | where isnull(WasCreated)
        // Summarize any number of events on the same resource Id into one.
        | summarize CollapsedEvents = count(TimeStamp), arg_max(TimeStamp, Operation, targetResourceType, tenantId, subscriptionId, resourceGroup, resourceName, $propertyNameNew $resourceExtensionAttributes), arg_min(MinTimeStamp = TimeStamp, id, $propertyNameOld) by resourceId
        | extend Operation = iif(tostring($propertyNameOld) == tostring($propertyNameNew), 'NonChange-Update', Operation)
        | extend resourceURL = strcat('https://portal.azure.com/#@', tenantId, '/resource', resourceId)
        | project Operation, CollapsedEvents, targetResourceType, subscriptionId, resourceGroup, name = resourceName, TimeStamp, MinTimeStamp, resourceURL, $propertyNameOld, $propertyNameNew $resourceExtensionAttributes
        | sort by TimeStamp desc
        "
    
}
