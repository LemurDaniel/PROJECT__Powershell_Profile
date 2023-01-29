
<#
    .SYNOPSIS
    Deactivate an activated eligible Pim-Assignment on a scope.

    .DESCRIPTION
    Deactivate an activated eligible Pim-Assignment on a scope. At the moment only management groups.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The resulting deactivation API-Response with the scope and roledefinition id.


    .EXAMPLE

    Deactivate the Tag Contributor on Managment Group 'acfroot-prod':

    PS> New-PimSelfDeactivationRequest -scope 'acfroot-prod' -Role 'Tag Contributor' -Verbose
    
.LINK
        
#>
function New-PimSelfDeactivationRequest {

    [Alias('pimDeactivate')]
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

        # The scope of the active assignment.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'custom'
        )]
        [System.String]
        $scope,

        # The role of the active assignment.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'custom'
        )]
        [System.String]
        $role
    )

    if (![System.String]::IsNullOrEmpty($ProfileName)) {
        $pimProfile = (Get-PimProfiles).GetEnumerator() | Where-Object -Property Key -EQ -Value $ProfileName | Select-Object -ExpandProperty Value
        $scope = $pimProfile.Scope
        $role = $pimProfile.Role
    }

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
