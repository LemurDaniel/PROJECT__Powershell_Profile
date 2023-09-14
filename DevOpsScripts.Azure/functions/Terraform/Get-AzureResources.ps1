





function Get-AzureResources {

    param (
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $AzurermResource
    )

    $providerResource = $AzurermResource -split '\.' | Select-Object -First 1 
    $providerResource = Get-TerraformAzuremMapping -ProviderResource $providerResource

    switch ($providerResource.slug) {

        'policy_definition' {
            return Get-AzPolicyDefinition -Custom
            | Select-Object -Property *, 
            @{
                Name       = "slug"; 
                Expression = { $_.properties.DisplayName }
            },
            @{
                Name       = "importId"; 
                Expression = { $_.PolicyDefinitionId }
            }
        }

        'policy_set_definition' {
            return Get-AzPolicySetDefinition -Custom
            | Select-Object -Property *, 
            @{
                Name       = "slug"; 
                Expression = { $_.properties.DisplayName }
            },
            @{
                Name       = "importId"; 
                Expression = { $_.PolicyDefinitionId }
            }
        }

        { $_ -in @(
                'management_group_policy_assignment',
                'subscription_policy_assignment',
                'resource_group_policy_assignment',
                'resource_policy_assignment'
            ) 
        } {
            Get-AzPolicyAssignment 
            | Select-Object -Property *, 
            @{
                Name       = "slug"; 
                Expression = { $_.Name }
            },
            @{
                Name       = "importId"; 
                Expression = { $_.PolicyAssignmentId }
            }
        }
        
        'role_definition' {
            return Get-AzRoleDefinition -Custom
            | Select-Object -Property *, 
            @{
                Name       = "slug"; 
                Expression = { $_.Name }
            },
            @{
                Name       = "importId"; 
                Expression = { $_.Id }
            }
        }

        'role_assignment' { 
            return Get-AzRoleAssignment 
            | Select-Object -Property *, 
            @{
                Name       = "slug"; 
                Expression = { @($_.RoleDefinitionName, $_.DisplayName, $_.Scope ) -join '/' }
            },
            @{
                Name       = "importId"; 
                Expression = { $_.RoleAssignmentId }
            }
        }

        'role_assignment_marketplace' {
            return '--TODO--'
        }

        'resource_group' {
            return  Get-AzResourceGroup 
            | Select-Object -Property *, 
            @{
                Name       = "slug"; 
                Expression = { $_.ResourceGroupName }
            },
            @{
                Name       = "importId"; 
                Expression = { $_.ResourceId }
            }
        }

        Default {  }
    }  


    if ($null -EQ $providerResource.azureType) {
        return "--TODO--"
    }


    return Get-AzResource -ResourceType $azureType
    | Select-Object -Property *, 
    @{
        Name       = "slug"; 
        Expression = { @($_.ResourceGroupName, $_.Name) -join '/' }
    },
    @{
        Name       = "importId"; 
        Expression = { $_.ResourceId }
    }
}