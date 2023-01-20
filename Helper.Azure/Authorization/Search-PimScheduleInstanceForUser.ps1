function Search-PimScheduleInstanceForUser {

    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $scope,

        [Parameter(Mandatory = $true)]
        [System.String]
        $role,

        [Parameter(Mandatory = $true)]
        [System.String]
        $aadUserId
    )


    # Get PIM Groups, User is Member of.
    $Request = @{
        Method = 'GET'
        Uri    = "https://graph.microsoft.com/v1.0/users/$aadUserId/transitiveMemberOf"
    }
    $responseGroups = Invoke-AzRestMethod @Request

    # Filter Out PIM-Groups
    $pimGroups = $responseGroups.Content | ConvertFrom-Json -Depth 8 | Select-Object -ExpandProperty value | `
        Where-Object { $_.Description -and $_.displayName.Contains('pimv3') -and $_.displayName.Contains('eligible__BASE') }

    # Get Eligiblity Schedule Instance on Scope
    $Request = @{
        Method = 'GET'
        Scope  = "/managementGroups/$scope"
        API    = 'providers/Microsoft.Authorization/roleEligibilityScheduleInstances?api-version=2020-10-01'
    }
    $eligibleScheduleInstance = Invoke-AzureRest @Request -return 'value.properties' | `
        Where-Object -Property principalId -In ($pimGroups.id) | `
        Where-Object { $_.expandedProperties.roleDefinition.displayName -eq $role }
    
    if (-not $eligibleScheduleInstance) {
        throw "Not Eligible Schedule Instance found for Role '$role' on scope '$scope' on principalId '$aadUserId'"
    }

    return $eligibleScheduleInstance
}