function New-PimSelfActivationRequest {

    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $justification,

        [Parameter(Mandatory = $true)]
        [System.int32]
        [ValidateScript(
            { 
                $_ -ge 1 -AND $_ -le 8
            },
            ErrorMessage = 'Duration must be between 1 and 8 Hours inclusive.'
        )]
        $duration,

        [Parameter(Mandatory = $true)]
        [System.String]
        $scope,

        [Parameter(Mandatory = $true)]
        [System.String]
        $role,

        [Parameter()]
        [ValidateSet(       
            'SelfActivate',
            'SelfDeactivate',
            'SelfExtend',
            'SelfRenew'
        )]
        [System.String]
        $requestType = 'SelfActivate'
    )


    # Get PIM Groups, User is Member of.
    $aduser = Get-AzADUser -Mail (Get-AzContext).Account.Id
    $Request = @{
        Method = 'GET'
        Uri    = "https://graph.microsoft.com/v1.0/users/$($adUser.id)/transitiveMemberOf"
    }
    $responseGroups = Invoke-AzRestMethod @Request

    # Filter Out PIM-Groups
    $pimGroups = $responseGroups.Content | ConvertFrom-Json -Depth 8 | Select-Object -ExpandProperty value | `
        Where-Object { $_.Description -and $_.displayName.Contains('pimv3') -and $_.displayName.Contains('eligible__BASE') }



    # Get Eligiblity Schedule Instance
    $Request = @{
        Method = 'GET'
        Scope  = "/managementGroups/$scope"
        API    = 'providers/Microsoft.Authorization/roleEligibilityScheduleInstances?api-version=2020-10-01'
    }
    $scheduleInstance = Invoke-AzureRest @Request -return 'value.properties' | `
        Where-Object -Property principalId -In ($pimGroups.id) | `
        Where-Object { $_.expandedProperties.roleDefinition.displayName -eq $role }
    
    if (-not $scheduleInstance) {
        throw "Not ScheduleInstance found for Role '$role' on scope '$scope'"
    }


    $Request = @{
    
        Method = 'PUT'
        Scope  = "managementGroups/$Scope"
        API    = "/providers/Microsoft.Authorization/roleAssignmentScheduleRequests/$([GUID]::NewGuid())`?api-version=2020-10-01"
        Body   = @{
            properties = @{
                requestType                     = $requestType
                justification                   = $justification

                linkedRoleEligibilityScheduleId = $scheduleInstance.roleEligibilityScheduleId.split('/')[-1]
                principalId                     = $adUser.id

                roleDefinitionId                = $scheduleInstance.expandedProperties.roleDefinition.id
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

New-PimSelfActivationRequest -requestType 'SelfDeactivate' -Justification 'Test PIM deactivation via API' `
    -duration 1 -scope 'acfroot-prod' -Role 'Tag Contributor' -Verbose
#>