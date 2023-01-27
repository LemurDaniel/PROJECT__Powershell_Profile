function New-PimSelfActivationRequest {

    [cmdletbinding()]
    param(
        # The name of the Context to switch to.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = 'Profile'  
        )]
        [ValidateScript(
            { 
                $_ -in (Get-PimProfiles).Keys
            },
            ErrorMessage = 'Please specify the correct Context.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-PimProfiles).Keys
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $ProfileName,


        [Parameter(
            Position = 1,
            Mandatory = $true,
            ParameterSetName = 'Profile'  
        )]
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Custom'  
        )]
        [System.String]
        $justification,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Custom'  
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
            Mandatory = $true,
            ParameterSetName = 'Custom'  
        )]
        [System.String]
        $scope,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Custom'  
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

    if ($ProfileName) {
        $pimProfile = (Get-PimProfiles).GetEnumerator() | Where-Object -Property Key -EQ -Value $ProfileName

        $scope = $pimProfile.Scope
        $role = $pimProfile.role
        $duration = $pimProfile.duration
    }

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