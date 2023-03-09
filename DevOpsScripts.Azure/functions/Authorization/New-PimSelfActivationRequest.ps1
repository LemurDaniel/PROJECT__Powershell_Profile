
<#
    .SYNOPSIS
    Activate a Eligible Pim-Assignment on a scope or for a Pim-Profile or for a scope and role via the API.

    .DESCRIPTION
    Activate a Eligible Pim-Assignment on a scope or for a Pim-Profile or for a scope and role via the API.
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

    [Alias('pim')]
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
            Position = 1,
            Mandatory = $true
        )]
        [System.String]
        $justification,

        # Generate a PIM-Justification from a workitem.
        [Parameter()]
        [switch]
        $useWorkItem,

        # Ignore branch in combination with use workitem.
        [Parameter()]
        [switch]
        $ignoreBranch,

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
        [ValidateRange(1, 8)]
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

    if ($PSBoundParameters.ContainsKey('useWorkItem')) {
        $justification = New-PimJustification -Justification $justification -noClipboard -ignoreBranch:$ignoreBranch
    }

    if (![System.String]::IsNullOrEmpty($ProfileName)) {
        $pimProfile = (Get-PimProfiles).GetEnumerator() | Where-Object -Property Key -EQ -Value $ProfileName | Select-Object -ExpandProperty Value
        $scope = $pimProfile.Scope
        $role = $pimProfile.Role
        $duration = $duration -eq 0 ? $pimProfile.Duration : $duration
    }

    $aadUser = Get-AzADUser -Mail (Get-AzContext).Account.Id
    $eligibleScheduleInstance = Search-PimScheduleInstanceForUser -aadUserId $aadUser.Id -scope $scope -role $role

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

    try {
        return Invoke-AzureRest @Request | Select-Object -ExpandProperty 'properties'
    }
    catch {
        if ($_.Exception.Message.Contains('RoleAssignmentExists')) {
            Write-Host -ForegroundColor Green "`n... No Action required - Role Assigmnet already active.`n"
        }
        else {
            throw $_
        }
    }

}