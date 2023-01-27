
<#
    .SYNOPSIS
    Activate a Eligible Pim-Assignment on a scope or for a Pim-Profile.

    .DESCRIPTION
    Activate a eligible Pim-Assignment on a scope. At the moment only management groups.
    Fails if a eligible schedule instance can't be found for the current user.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The resulting activation API-Response with links to the roleAssignment and Eligibility schedule Id.


    .EXAMPLE

    Activate the Tag Contributor on Managment Group 'acfroot-prod':

    PS> New-PimSelfActivationRequest -Justification 'Test PIM activation via API' `
    -duration 1 -scope 'acfroot-prod' -Role 'Tag Contributor' -Verbose

    .EXAMPLE

    Extend the Tag Contributor on Managment Group 'acfroot-prod':

    PS> New-PimSelfActivationRequest -requestType 'SelfExtend' -Justification 'Test PIM extension via API' `
    -duration 1 -scope 'acfroot-prod' -Role 'Tag Contributor' -Verbose

    
    .LINK
        
#>
function New-PimSelfActivationRequest {

    [cmdletbinding()]
    param(
        # A PIM-Profile to choose from.
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

        # A justification for activating pim.
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $justification,

        # A duration for the activation.
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'Profile'
        )]
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'custom'
        )]
        [System.int32]
        [ValidateScript(
            { 
                $_ -ge 1 -AND $_ -le 8
            },
            ErrorMessage = 'Duration must be between 1 and 8 Hours inclusive.'
        )]
        $duration,

        # Scope for the PIM-Acitvation at the Moment only Management Groups.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'custom'
        )]
        [System.String]
        $scope,

        # The Role for PIM-Acitvation.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'custom'
        )]
        [System.String]
        $role,

        # The Request Type. activation, extension.
        [Parameter()]
        [ValidateSet(       
            'SelfActivate',
            'SelfExtend'
        )]
        [System.String]
        $requestType = 'SelfActivate'
    )

    $pimProfile = (Get-PimProfiles).GetEnumerator() | Where-Object -Property Key -EQ -Value $ProfileName | Select-Object -ExpandProperty Value
    $scope = $pimProfile.Scope
    $role = $pimProfile.Role
    $duration = $duration -eq 0 ? $pimProfile.Duration : $duration

    $aadUser = Get-AzADUser -Mail (Get-AzContext).Account.Id
    $eligibleScheduleInstance = Search-PimScheduleInstance -scope $scope -role $role

    $Request = @{
    
        Method = 'PUT'
        Scope  = $scope
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