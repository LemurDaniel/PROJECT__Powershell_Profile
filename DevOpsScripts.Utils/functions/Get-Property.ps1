
<#
    .SYNOPSIS
    Gets a chached value by a type and a specified identifier.

    .DESCRIPTION
    Gets a chached value by a type and a specified identifier.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Return null or the Cached value if present.

    .EXAMPLE

    Many Methods implement this Method:
    Get All Names of the Teams in the current Project-Context:

    PS> Get-ProjectInfo -return teams.name

    .EXAMPLE

    Get all the DisplayName Property of all Role Management Policy Assignments on a Management Group:

    PS> $roleManagementPolicyAssignments = Get-RoleManagmentPoliciyAssignmentsForScope -scope /managementGroups/acfroot-dev
    PS> Get-Property -Object $roleManagementPolicyAssignments -return 'properties.policyAssignmentProperties.roleDefinition.displayName'


    .LINK
        
#>

function Get-Property {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Object,

        [Alias('Property', 'return')]
        [Parameter(Mandatory = $false)]
        [System.String]
        $PropertyPath
    )

    if ([System.String]::isNullOrEmpty($PropertyPath)) {
        return $Object
    }


    $segmented = '.' + $PropertyPath.toLower() -replace '[\/\.]+', '.'

    while ($segmented) {

        Write-Verbose '_----------------------------_'
        Write-Verbose ($Object.GetType().BaseType ?? $Object.GetType().Name)

        $objectProperties = $Object.PSObject.Properties
        if ($Object.GetType().BaseType -eq [System.Array]) {
            $objectProperties = $Object[0].PSObject.Properties
        }

        Write-Verbose ($objectProperties.Name | ConvertTo-Json)

        $Target = $objectProperties | `
            Where-Object { $segmented.Contains('.' + $_.Name.toLower()) } | `
            Sort-Object -Property @{ Expression = { $segmented.IndexOf('.' + $_.Name.toLower()) } } | `
            Select-Object -First 1

        if ($null -eq $Target) {
            Throw "Path: '$PropertyPath' - Error at '$segmented' - is NULL"
        }

        Write-Verbose "$segmented, $($Target.name.toLower())"
        $segmented = $segmented -replace "\.$($Target.name.toLower())", ''
        Write-Verbose "$segmented, $($Target.name.toLower())"
        $Object = $Object."$($Target.name)" # Don't use Target Value, in case $object is Array and multiple need to be returned
    }

    return $Object
}