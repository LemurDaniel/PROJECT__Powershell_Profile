function New-PimSelfDeactivationRequest {

    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $scope,

        [Parameter(Mandatory = $true)]
        [System.String]
        $role
    )

    $aadUser = Get-AzADUser -Mail (Get-AzContext).Account.Id
    $eligibleScheduleInstance = Search-PimScheduleInstance -scope $scope -role $role

    $Request = @{
    
        Method = 'PUT'
        Scope  = "managementGroups/$Scope"
        API    = "/providers/Microsoft.Authorization/roleAssignmentScheduleRequests/$([GUID]::NewGuid())`?api-version=2020-10-01"
        Body   = @{
            properties = @{
                requestType                     = 'SelfDeactivate'
                justification                   = ''
                principalId                     = $aadUser.id

                linkedRoleEligibilityScheduleId = $eligibleScheduleInstance.roleEligibilityScheduleId.split('/')[-1]
                roleDefinitionId                = $eligibleScheduleInstance.expandedProperties.roleDefinition.id

                scheduleInfo                    = @{
                    expiration    = @{
                        endDateTime = $null
                        duration    = $null
                        type        = $null
                    }
                    startDateTime = [DateTime]::now
                }
            }
        }
    }

    return Invoke-AzureRest @Request -return 'properties'
}
