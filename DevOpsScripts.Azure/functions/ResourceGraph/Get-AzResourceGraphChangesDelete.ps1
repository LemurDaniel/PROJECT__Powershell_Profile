


# TODO
function Get-AzResourceGraphChangesCreate {


    [CmdletBinding()]
    param (
        # The resourceType to filter change events from.
        [Parameter(Mandatory = $true)]
        [System.String]
        $resourceType,

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


.......TODO
        Filter for resources that were created, then deleted with a time lived => 2 hours, etc.
        "
    
}

<#

Get-AzResourceGraphChangesDelete -resourceType 'microsoft.compute/disks'

Get-AzResourceGraphChangesDelete -resourceType 'microsoft.compute/virtualmachines'

#>
