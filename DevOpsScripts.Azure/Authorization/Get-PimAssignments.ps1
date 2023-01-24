function Get-PimAssignments {

    [cmdletbinding()]
    param()

    $Cache = Get-UtilsCache -Type PIM -Identifier assignments
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
        
            $Request = @{
                Method = 'GET'
                Scope  = "/managementGroups/$($_.scope)"
                API    = 'providers/Microsoft.Authorization/roleEligibilityScheduleInstances?api-version=2020-10-01'
            }

            $scheduleInstances = Invoke-AzureRest @Request -return 'value.properties' | Where-Object -Property principalId -EQ -Value $_.id
    
            return $scheduleInstances
        }
    } | `
        Where-Object -Property PIM_Configuration -NE -Value $false


    return Set-UtilsCache -Object $pimGroups -Type PIM -Identifier assignments
}