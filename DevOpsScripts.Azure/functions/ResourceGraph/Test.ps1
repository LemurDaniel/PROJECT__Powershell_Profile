


# Test - Abstract Query to get change events on any resource  with some customization. back x-days.
function Get-AzResourceGraphChangesUpdateTest {


    [CmdletBinding()]
    param (
        # The resourceType to filter change events from.
        [Parameter(Mandatory = $true)]
        [System.String]
        $resourceType,

        # The change attribute to capture
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $updateAttributes,
        
        # The change attribute to capture
        [Parameter(Mandatory = $false)]
        [System.Collections.Hashtable]
        $ResourceAttributes = @{},

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
        $TimeStamp = [System.DateTime]::Now.AddDays(-7),

        # Mangement Group Scope on which to perform query. Will default to tennand id.
        [Parameter(Mandatory = $false)]
        [System.String]
        $managementGroup
    )

    $managementGroup = [System.String]::IsNullOrEmpty($managementGroup) ? (Get-AzContext).Tenant.Id : $managementGroup
    $updateAttributesExtensionsPrev = $updateAttributes.Keys.Count -gt 0 ? ", $(($updateAttributes.Keys | ForEach-Object { "previous$($_.split('.')[-1])" }) -join ',' )" : ''
    $updateAttributesExtensionsNew = $updateAttributes.Keys.Count -gt 0 ? ", $(($updateAttributes.Keys | ForEach-Object { "new$($_.split('.')[-1])" }) -join ',' )" : ''
    $ResourceAttributesExtensions = $ResourceAttributes.Keys.Count -gt 0 ? ", $($ResourceAttributes.Keys -join ',' )" : ''

    #Search-AzGraph -ManagementGroup $managementGroup -Query
    return "
        resourcechanges
        | where properties.targetResourceType =~ '$resourceType' 
        // Get only Changes after Timestamp of Type Update.
        | where properties.changeType =~ 'Update'
        | where properties.changeAttributes.timestamp > datetime($TimeStamp)
        | where $( ($updateAttributes.Keys | ForEach-Object { "properties has '$_'" }) -join ' and ' )
        | extend Operation = properties.changeType
        // Get Basic Change Attributes.
        | extend TimeStamp = tostring(properties.changeAttributes.timestamp)
        | extend resourceId = tolower(tostring(properties.targetResourceId))
        | extend resourceName = split(resourceId,'/')[-1]
        $(
            $updateAttributes.GetEnumerator() | ForEach-Object { 
                $attribute = "properties.changes.['$($_.Key)'].previousValue"
                "| extend previous$($_.Key.split('.')[-1]) = $($_.Value -replace '\$1', $attribute)`n" 
            }
            $updateAttributes.GetEnumerator() | ForEach-Object { 
                $attribute = "properties.changes.['$($_.Key)'].newValue"
                "| extend new$($_.Key.split('.')[-1]) = $($_.Value -replace '\$1', $attribute)`n" 
            }
        )
        // Check for existence of resource. (In case resource was deleted, then ignore update events.)
        | join kind=leftouter (
            resources 
            | where type =~ '$resourceType' 
            | extend id = tolower(id)
            | extend joinResExistent = true
            $(
                $ResourceAttributes.GetEnumerator() | ForEach-Object { "| extend $($_.Key) = $($_.Value)`n" }
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
        | summarize CollapsedEvents = count(TimeStamp), arg_max(TimeStamp, Operation, tenantId, subscriptionId, resourceGroup, resourceName $ResourceAttributesExtensions $ResourceAttributesExtensions $updateAttributesExtensionsPrev), arg_min(MinTimeStamp = TimeStamp, id) by resourceId
        | extend resourceURL = strcat('https://portal.azure.com/#@', tenantId, '/resource/', resourceId)
        | project Operation, CollapsedEvents, subscriptionId, resourceGroup, name = resourceName, TimeStamp, MinTimeStamp, resourceURL $ResourceAttributesExtensions $updateAttributesExtensionsPrev $updateAttributesExtensionsNew
        | sort by TimeStamp desc
        "
    
}

<#
Get-AzResourceGraphChangesUpdateTest -resourceType  'microsoft.compute/disks' `
     -updateAttributes @{
        diskSizeBytes = '$1'
        tier          = '$1'
    }
Get-AzResourceGraphChangesUpdateTest -resourceType  'microsoft.compute/disks' `
     -updateAttributes @{
        "properties.diskSizeBytes" = 'format_bytes(tolong(iif(isnull($1), 0, $1)))'
        "properties.tier"          = '$1'
    }
        tier          = '$1'

Get-AzResourceGraphChangesUpdateTest -resourceType  'microsoft.compute/disks' `
     -updateProperty 'diskSizeBytes' -format 'format_bytes(tolong($1))'

Get-AzResourceGraphChangesUpdateTest -resourceType 'microsoft.compute/virtualmachines' `
    -updateProperty 'hardwareProfile.vmSize' `
    -ResourceAttributes @{
    vmSize              = 'properties.hardwareProfile.vmSize'
    acfVmOperatingHours = 'tags.acfVmOperatingHours'
}

#>