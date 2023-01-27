function New-PimSelfActivationRequest {

    [cmdletbinding()]
    param(
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $justification,

        [Parameter(
            Mandatory = $true
        )]
        [System.int32]
        [ValidateScript(
            { 
                $_ -ge 1 -AND $_ -le 8
            },
            ErrorMessage = 'Duration must be between 1 and 8 Hours inclusive.'
        )]
        $duration,

        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $scope,

        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $role,

        [Parameter()]
        [ValidateSet(       
            'SelfActivate',
            'SelfExtend',
            'SelfRenew'
        )]
        [System.String]
        $requestType = 'SelfActivate'
    )

    $aadUser = Get-AzADUser -Mail (Get-AzContext).Account.Id
    $eligibleScheduleInstance = Search-PimScheduleInstance -scope $scope -role $role

    $Request = @{
    
        Method = 'PUT'
        Scope  = "managementGroups/$Scope"
        API    = "/providers/Microsoft.Authorization/roleAssignmentScheduleRequests/$([GUID]::NewGuid())`?api-version=2020-10-01"
        Body   = @{
            properties = @{
                requestType                     = $requestType
                justification                   = $justification
                principalId                     = $aadUser.id

                linkedRoleEligibilityScheduleId = $eligibleScheduleInstance.roleEligibilityScheduleId.split('/')[-1]
                roleDefinitionId                = $eligibleScheduleInstance.expandedProperties.roleDefinition.id
                scheduleInfo                    = @{
                    expiration    = @{
                        endDateTime = $null
                        duration    = "PT$duration`H"
                        type        = 'AfterDuration'
                    }
                    startDateTime = [DateTime]::now
                }
            }
        }
    }

    return Invoke-AzureRest @Request -return 'properties'

}

<#
New-PimSelfActivationRequest -Justification 'Test PIM activation via API' `
    -duration 1 -scope 'acfroot-prod' -Role 'Tag Contributor' -Verbose

New-PimSelfActivationRequest -requestType 'SelfExtend' -Justification 'Test PIM extension via API' `
    -duration 1 -scope 'acfroot-prod' -Role 'Tag Contributor' -Verbose

New-PimSelfDeactivationRequest -scope 'acfroot-prod' -Role 'Tag Contributor' -Verbose
#>