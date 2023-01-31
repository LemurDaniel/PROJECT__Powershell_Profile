


# DC Migration Specific because of PIM-Group Naming. For testing.
function Get-PimAssignments {

    [cmdletbinding()]
    param()

    $Cache = $null# Get-UtilsCache -Type PIM -Identifier assignments
    if ($Cache) {
        return $Cache
    }

    # Get PIM Groups, User is Member of.
    $aduser = Get-AzADUser -Mail (Get-AzContext).Account.Id
    $Request = @{
        Method = 'GET'
        Uri    = "https://graph.microsoft.com/v1.0/users/$($adUser.id)/transitiveMemberOf"
    }
    $responseGroups = Invoke-AzRestMethod @Request


    $pimGroups = $responseGroups.Content | ConvertFrom-Json -Depth 8 | Select-Object -ExpandProperty value | `
        Where-Object { $_.Description -and $_.displayName.Contains('pimv3') -and $_.displayName.Contains('eligible__BASE') } | `
        Select-Object @{
        Name       = 'type';
        Expression = { $_.displayName.split('_')[2] }    
    }, @{
        Name       = 'scope';
        Expression = { $_.displayName.split('_')[3] }    
    }, @{
        Name       = 'assignment';
        Expression = { ($_.displayName.split('_')[4..10] -join '_').replace('_eligible__BASE', '') }  
    }, @{
        Name       = 'id';
        Expression = { $_.id }    
    } | `
        Select-Object *, @{
        Name       = 'PIM_Configuration';
        Expression = {
            if ($_.type -ne 'mgmt') {
                return $false
            }
        
            $scope = "/managementGroups/$($_.scope)"
            Write-Host "Fetching PIM for Scope: $Scope - $($_.assignment)"
           
            return Get-RoleEligibilitySceduleInstancesForScope $scope | `
                Where-Object -Property principalId -EQ -Value $_.id | `
                Select-Object *, @{
                Name       = 'expirationEndUserAssignment';
                Expression = {
                    Search-In (Get-RoleManagmentPoliciyAssignmentsForScope $scope) `
                        -where 'properties.policyAssignmentProperties.roleDefinition.id' `
                        -has $_.roleDefinitionId  `
                        -return 'Properties.effectiveRules' | `
                        Where-Object -Property id -EQ -Value 'Expiration_EndUser_Assignment'
                }
            }
            
            
        }
    } | `
        Where-Object -Property PIM_Configuration -NE -Value $false | `
        ForEach-Object {
        Add-PimProfile -ProfileName "$($_.assignment)--$($_.scope)" `
            -Scope $_.PIM_Configuration.scope `
            -Role $_.PIM_Configuration.expandedProperties.roleDefinition.displayName `
            -duration ($_.PIM_Configuration.expirationEndUserAssignment.maximumDuration -replace '[^\d]*', '') -Force
    }


    return Get-PimProfiles
    #return Set-UtilsCache -Object $pimGroups -Type PIM -Identifier assignments
}