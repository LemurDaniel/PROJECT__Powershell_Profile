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

    # This is useful for example for Azure-Reservations that can then be done based on changes of VmSizes.

    PS> Get-AzResourceGraphChangesUpdate -ResourceType 'microsoft.compute/virtualmachines' `
            -UpdateProperty 'properties.hardwareProfile.vmSize' `
            -ResourceAttributes @{
                acfVmOperatingHours = 'tags.acfVmOperatingHours'
            }


    .EXAMPLE

    Get updates of disks on 'diskSizeBytes' formated as bytes with additional sku Attributes:

    PS> Get-AzResourceGraphChangesUpdate -ResourceType  'microsoft.compute/disks' `
            -UpdateProperty 'properties.diskSizeBytes' -format 'format_bytes(tolong($1))' `
            -ResourceAttributes @{
                skuName           = 'sku.name'
                skuTier           = 'sku.tier'
            }


   .EXAMPLE

    Get any Changes on Virtual Machine Powerstates and addtional tags in the last 8-Hours:

    PS> Get-AzResourceGraphChangesUpdate -ResourceType  'microsoft.compute/virtualmachines' `
            -TimeStamp ([DateTime]::Now.AddHours(-8)) `
            -UpdateProperty 'properties.extended.instanceView.powerState.code' `
            -ResourceAttributes @{
                tags                = 'tags'
                acfVmOperatingHours = 'tags.acfVmOperatingHours'
            }


               
    .EXAMPLE

    Get any Changes on Virtual Machine Powerstates and addtional acfVmOperatingHours in from 'yesterday at 0:00' until '24 Hours later':

    PS> $TimeStamp = [DateTime]::Now.Date.AddDays(-1)
    PS> Get-AzResourceGraphChangesUpdate -ResourceType  'microsoft.compute/virtualmachines' `
            -TimeStamp $TimeStamp  `
            -TimeStampEnd $TimeStamp.AddHours(24) `
            -UpdateProperty 'properties.extended.instanceView.powerState.code' `
            -ResourceAttributes @{
                acfVmOperatingHours = 'tags.acfVmOperatingHours'
            }
        # (DC-Migration specific)
        # The correct working of acfVmOperatingHours start/shutdown can be seen by comparing MinTimeStamp and TimeStamp with acfOperatingHours.

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
            'contains', #Case-InSensitive
            '!contains', #Case-InSensitive
            'endswith', #Case-InSensitive
            '!endwith', #Case-InSensitive
            'startswith', #Case-InSensitive
            '!startswith', #Case-InSensitive
            'matches regex'
        )]
        [System.String]
        $ResourceTypeFilter = '=~',

        # The ResourceType to filter change events for.
        [Parameter(
            Position = 1,
            Mandatory = $true
        )]
        [System.String]
        $ResourceType,
        
        # The change attribute to capture the previous and new value from.
        [Parameter(Mandatory = $true)]
        [System.String]
        $UpdateProperty,
        
        # Any change attributes to capture on the change events.
        [Parameter(Mandatory = $false)]
        [System.String]
        $format = '$1',

        # Any additional Resource attributes to be returned from the changed resource.
        [Parameter(Mandatory = $false)]
        [System.Collections.Hashtable]
        $ResourceAttributes = @{},

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

    $TimeStamp = $TimeStamp ? $TimeStamp : [DateTime]::Now.AddDays(-7)
    $TimeStampEnd = $TimeStampEnd ? $TimeStampEnd : [DateTime]::Now.AddDays(1)

    $managementGroup = [System.String]::IsNullOrEmpty($managementGroup) ? (Get-AzContext).Tenant.Id : $managementGroup
    $resourceExtensionAttributes = $ResourceAttributes.Keys.Count -gt 0 ? ", $($ResourceAttributes.Keys -join ', ')" : ''

    #$TextInfo = [System.Globalization.CultureInfo]::GetCultureInfo('de').TextInfo
    #$UpdatePropertyName = $TextInfo.ToTitleCase($UpdateProperty.Split('.')[-1])

    $UpdatePropertyName = [System.Char]::ToUpper($UpdateProperty.split('.')[-1][0]) + $UpdateProperty.split('.')[-1].Substring(1)
    $propertyNameOld = "previous$UpdatePropertyName"
    $propertyNameNew = "new$UpdatePropertyName"
    return Search-AzResourceGraphResults -ManagementGroup $managementGroup -Query "
        resourcechanges
        | where properties.targetResourceType $ResourceTypeFilter '$ResourceType' 
        // Get only Changes after Timestamp of Type Update.
        | where properties.changeType =~ 'Update'
        | where properties.changeAttributes.timestamp > datetime($TimeStamp)
        | where properties.changeAttributes.timestamp < datetime($TimeStampEnd)
        | where properties has '$UpdateProperty'
        | extend Operation = properties.changeType
        // Get Basic Change Attributes.
        | extend targetResourceType = properties.targetResourceType
        | extend TimeStamp = tostring(properties.changeAttributes.timestamp)
        | extend resourceId = tolower(tostring(properties.targetResourceId))
        $([System.String]::IsNullOrEmpty($regexMatchId)     ? ' ' : "| where resourceId matches regex '$regexMatchId'" )
        | extend resourceName = split(resourceId,'/')[-1]
        $([System.String]::IsNullOrEmpty($NameStartsWith)   ? ' ' : "| where resourceName startswith '$NameStartsWith'" )
        $([System.String]::IsNullOrEmpty($NameContains)     ? ' ' : "| where resourceName contains '$NameContains'" )
        | extend oldValue = properties.changes.['$UpdateProperty'].previousValue
        | extend newValue = properties.changes.['$UpdateProperty'].newValue
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
            | where properties.changeAttributes.timestamp < datetime($TimeStampEnd)
            | where properties.changeType =~ 'Create'
            | extend WasCreated = true
            | extend resourceId = tolower(tostring(properties.targetResourceId))
        ) on `$left.resourceId == `$right.resourceId
        | where isnull(WasCreated)
        // Summarize any number of events on the same resource Id into one.
        | summarize CollapsedEvents = count(TimeStamp), arg_max(TimeStamp, Operation, targetResourceType, tenantId, subscriptionId, resourceGroup, resourceName, $propertyNameNew $resourceExtensionAttributes), arg_min(MinTimeStamp = TimeStamp, id, $propertyNameOld) by resourceId
        | extend Operation = iif(trim(' ',tostring($propertyNameOld)) == trim(' ',tostring($propertyNameNew)), 'NonChange-Update', Operation)
        | extend resourceURL = strcat('https://portal.azure.com/#@', tenantId, '/resource', resourceId)
        | project Operation, CollapsedEvents, targetResourceType, tenantId, subscriptionId, resourceGroup, name = resourceName, TimeStamp, MinTimeStamp, resourceId, resourceURL, $propertyNameOld, $propertyNameNew $resourceExtensionAttributes
        | sort by TimeStamp desc
        "
    
}
