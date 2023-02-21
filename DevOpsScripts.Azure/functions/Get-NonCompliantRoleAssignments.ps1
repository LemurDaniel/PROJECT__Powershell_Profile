
<#
.SYNOPSIS
    Returns a list of Non-Compliant RoleAssignments for a Policy assignment or Initiative assignment. (Note only works for RoleAssignments not other Resources)

.DESCRIPTION
   Returns a list of Non-Compliant RoleAssignments for a Policy assignment or Initiative assignment and Returns a list of additional Information like ResourceID, PrincipalName, PrincipalId, IsResourceExistent, etc.
   This only works for Policies that audit Resources of Type Roleassignments.

.EXAMPLE

    Get all Non-Compliant RoleAssignments for a Initative of Policy-Assignment in acfroot-prod

    PS> Get-NonCompliantRoleAssignments -ManagementGroupName 'acfroot-prod' -PolicyAssignmentName 'deny-priv-elevation-user'


.EXAMPLE
    Get all Non-Compliant RoleAssignments for specific policies in an Initiative-Assignment in acfroot-prod

    PS>  $nonCompliance_SPN += Get-NonCompliantRoleAssignments -ManagementGroupName "acfroot-prod" `
            -PolicyAssignmentName 'deny-priv-elevation-spn' `
            -PolicyDefinitionNames deny-priv-owner, deny-priv-contributor

.LINK
   

#>
function Get-NonCompliantRoleAssignments {
    param (
        # APIVersion of Azure REST-API used for retrieving REST-API-Versions for specific Resource Types.
        [Parameter()] 
        [System.String] 
        $APIVersionManagement = '2015-01-01',

        # APIVersion of Azure REST-API used for retrieving RoleAssignments.
        [Parameter()] 
        [System.String] 
        $APIVersionRoleAssignments = '2017-05-01',

        # The optional PolicyDefinitionIds (Useful with InitiativeAssignments, when only a specific policies are wanted)
        [Parameter()] 
        [System.String[]] 
        $PolicyDefinitionNames = @(),
                
        # The tenant from which Resources and Subscriptions are read.
        [Parameter()] 
        [System.String] 
        $TenantId = (Get-AzContext).Tenant.Id,

        # (Mandatory) The Initiative or Policy-Assignment ID.
        [Parameter(Mandatory = $true)] 
        [System.String] 
        $PolicyAssignmentName,

        # (Mandatory) The Managementgroup on which the Non-Compliance-Data is read from.
        [Parameter(Mandatory = $true)] 
        [System.String] 
        $ManagementGroupName
    )

    $PolicyAssignmentId = Get-AzPolicyAssignment -Scope "providers/Microsoft.Management/managementGroups/$managementGroupName" -Name $PolicyAssignmentName | Select-Object -ExpandProperty PolicyAssignmentId
    $PolicyDefinitionIds = $PolicyDefinitionNames | ForEach-Object { (Get-AzPolicyDefinition -ManagementGroupName $ManagementGroupName -Name $_  ).PolicyDefinitionId }


    $Filter = "ComplianceState eq 'NonCompliant' and PolicyAssignmentId eq '$PolicyAssignmentId'"
    if ($PolicyDefinitionIds.Count -gt 0) {
        $policyIds = $PolicyDefinitionIds | ForEach-Object { "PolicyDefinitionId eq '$_'" }
        $Filter += " and ( $($policyIds -join ' or ') )"
    }

    $nonComplianceDataList = Get-AzPolicyState -ManagementGroupName $ManagementGroupName -Filter $Filter | Sort-Object -Property ResourceId

    Write-Host 
    Write-Host "Processing $($nonComplianceDataList.Count) nonCompliant Resources for '$( ($PolicyAssignmentId -split '/')[-1] )'"
    Write-Host

    $MAXRETRIES = 1;
    $ErroredOutList = [System.Collections.ArrayList]::new()

    $CompiledNonCompliantList = [System.Collections.ArrayList]::new()
    $APIVersion_providers = [System.Collections.Hashtable]::new()
    $APIVersion_providers.Add('microsoft.labservices/*', '2018-10-15');


    $ErrorActionPreference = 'Stop'
    $ParsingList = $nonComplianceDataList;
    for ($index = 0; $index -lt $ParsingList.Count; $index++) {

        $nonComplianceData = $ParsingList[$index];

        # Select only certain properties from the compliance data.
        $nonCompliantObject = $nonComplianceData `
        | Select-Object -Property Timestamp, PolicyAssignmentName, PolicyDefinitionName, PolicyDefinitionAction, ComplianceState
 
        # Add properties regarding the resource on which the roleassignment is created.
        $RoleAssignmentId = $nonComplianceData.ResourceId
        $NonCompliantResourceId = ($RoleAssignmentId -split '/providers/microsoft.authorization/roleassignments/')[0].ToLower()

        $nonCompliantObject | Add-Member -MemberType NoteProperty -Name NonCompliantResourceId -Value $NonCompliantResourceId
        $nonCompliantObject | Add-Member -MemberType NoteProperty -Name IsResourceExistent -Value $false

        Write-Host "    Processing Resource $NonCompliantResourceId"

        try {
            # Split Resource id to get Provider Id.
            $splittedArray = $NonCompliantResourceId -split '/'
            $subscriptionId = $splittedArray[$splittedArray.indexOf('subscriptions') + 1];

            # Try getting the resource if it exists.
            $fetchedResource = $null
            if ( -not $NonCompliantResourceId.Contains('providers') -and -not $NonCompliantResourceId.Contains('resourcegroups')) {
                $fetchedResource = Get-AzSubscription -SubscriptionId $subscriptionId -Tenant $TenantId
            }
            elseif ( -not $NonCompliantResourceId.Contains('providers') ) {
                $null = Set-AzContext -SubscriptionId $subscriptionId -Tenant $TenantId
                $ResourceGroupName = $splittedArray[$splittedArray.indexOf('resourcegroups') + 1]
                $fetchedResource = Get-AzResourceGroup -ResourceGroupName $ResourceGroupName
            }
            elseif ($NonCompliantResourceId.Contains('providers') ) {
                $provider = $splittedArray[($splittedArray.IndexOf('providers') + 1)]
                $resourceType = $splittedArray[($splittedArray.IndexOf('providers') + 2)]


                # /providers/provider/resourceType/resourceName/subresourceType/subresourceName
                $subResourceType1_index = ($splittedArray.IndexOf('providers') + 4)
                if ( ($splittedArray.Count - 1) -ge $subResourceType1_index ) {
                    $resourceType += "/$( $splittedArray[($splittedArray.IndexOf('providers') + 4)] )"
                }
   
                if ( -not $APIVersion_providers.ContainsKey("$provider/$resourceType") -and (-not $APIVersion_providers.ContainsKey("$provider/*") )) {

                    # Get Recent API Versions for specified Provider
                    # Write-Host "https://management.azure.com/subscriptions/$subscriptionId/providers/$provider/?api-version=$APIVersionManagement"
                    $response = Invoke-AzRestMethod -Method GET -Uri "https://management.azure.com/subscriptions/$subscriptionId/providers/$provider/?api-version=$APIVersionManagement"
                    $resourceTypes = ($response.Content | ConvertFrom-Json).resourceTypes;

                    $recentApiVersion = $resourceTypes | Where-Object { $_.resourceType -eq $resourceType }
                    if ( $null -eq $recentApiVersion ) {
                        $recentApiVersion = $resourceTypes[0].apiVersions[0];
                    }
                    else {
                        $recentApiVersion = $recentApiVersion.apiVersions[0];
                    }

                    # Add API Version to hashtable
                    $APIVersion_providers.Add("$provider/$resourceType", $recentApiVersion)
                }
                
                $APIVersionProvider = $APIVersion_providers["$provider/$resourceType"] ?? $APIVersion_providers["$provider/*"]
                Write-Host "        Using API-Version '$APIVersionProvider' for '$provider/$resourceType'"
                $response = Invoke-AzRestMethod -Method GET -Uri "https://management.azure.com/$NonCompliantResourceId/?api-version=$APIVersionProvider"
            
                if ($response.StatusCode -eq 200) {
                    $fetchedResource = ($response.Content | ConvertFrom-Json)
                }
                elseif ($response.StatusCode -eq 404) {
                    Write-Host '        Resource not Found'
                }
                else {
                    throw $response.Content
                }
            }

            $nonCompliantObject.IsResourceExistent = ($null -ne $fetchedResource)
        }
        catch {
            $err = Resolve-AzError -Error $_;

            if ( $err.Message.Contains('Provided resource group does not exist') ) {
                Write-Host '        Resource not Found'
            }
            elseif ( StackTrace.Contains('Microsoft.Azure.Commands.Profile.GetAzureRMSubscriptionCommand.ThrowSubscriptionNotFoundError') ) {
                Write-Host '        Resource not Found'
            }
            else {
                $ErroredOutList += $nonComplianceData
                continue;
            }
        }


        # Add properties regarding the roleassignment itself.

        $nonCompliantObject | Add-Member -MemberType NoteProperty -Name principalId -Value 'Unknown'
        $nonCompliantObject | Add-Member -MemberType NoteProperty -Name principalName -Value 'Unknown'
        $nonCompliantObject | Add-Member -MemberType NoteProperty -Name principalType -Value 'Unknown'
        $nonCompliantObject | Add-Member -MemberType NoteProperty -Name RoleName -Value 'Unknown'
        $nonCompliantObject | Add-Member -MemberType NoteProperty -Name RoleAssignmentId -Value $RoleAssignmentId

        Write-Host '        Fetching Identity from AAD'
        try {
            $response = Invoke-AzRestMethod -Method GET -Uri "https://management.azure.com/$RoleAssignmentId/?api-version=$APIVersionRoleAssignments"
            if ($response.StatusCode -eq 400) {
                throw $response.Content
            }
        
            $RoleAssignmentResponse = ($response.Content | ConvertFrom-Json).properties
            $roleDefinitionId = ($RoleAssignmentResponse.roleDefinitionId -split '/')[-1]
            $nonCompliantObject.RoleName = (Get-AzRoleDefinition -Id $roleDefinitionId).Name
            $nonCompliantObject.principalId = $RoleAssignmentResponse.principalId

            $principal = $null
            switch ($RoleAssignmentResponse.principalType) {
                'Foreign' { 
                    $principal = Get-AzADGroup -ObjectId $RoleAssignmentResponse.principalId 
                    $nonCompliantObject.principalName = $principal.DisplayName 
                    $nonCompliantObject.principalType = 'ForeignGroup'
                }
                'Group' { 
                    $principal = Get-AzADGroup -ObjectId $RoleAssignmentResponse.principalId 
                    $nonCompliantObject.principalName = $principal.DisplayName 
                    $nonCompliantObject.principalType = $RoleAssignmentResponse.principalType 
                }
                'User' { 
                    $principal = Get-AzADUser -ObjectId $RoleAssignmentResponse.principalId 
                    $nonCompliantObject.principalName = $principal.DisplayName 
                    $nonCompliantObject.principalType = $RoleAssignmentResponse.principalType 
                }
                'ServicePrincipal' { 
                    $principal = Get-AzADServicePrincipal -ObjectId $RoleAssignmentResponse.principalId 
                    $nonCompliantObject.principalName = $principal.DisplayName 
                    $nonCompliantObject.principalType = $RoleAssignmentResponse.principalType 
                }
                Default {
                    throw "ERROR: Principaltype ${$RoleAssignmentResponse.principalType} not found"
                }
            }

        }
        catch {
            Write-Host '        Principal not Found'
        }

        $CompiledNonCompliantList += $nonCompliantObject

        # Retrie Resources that may errored out not because of the Resource missing. Like Connection Timeout.
        if ($index -eq ($ParsingList.count - 1) -and $MAXRETRIES-- -gt 0) {
            $index = 0;
            $ParsingList = $ErroredOutList;
            $ErroredOutList = [System.Collections.ArrayList]::new();
        }
    }

    
    # Order properties in a nice way.
    $CompiledNonCompliantList = $CompiledNonCompliantList `
    | Sort-Object -Property PolicyAssignmentName, PolicyDefinitionName
    | Select-Object -Property Timestamp, PolicyAssignmentName, PolicyDefinitionName, PolicyDefinitionAction, ComplianceState, RoleName, principalName, principalType, principalId, IsResourceExistent, NonCompliantResourceId, RoleAssignmentId

    return $CompiledNonCompliantList
}


