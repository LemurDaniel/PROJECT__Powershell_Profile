
<#
    .SYNOPSIS
    Change properties and extend the Lifetime of a PAT if still valid.

    .DESCRIPTION
    Change properties and extend the Lifetime of a PAT if still valid.

    .INPUTS
    You can pipe PAT-responses into the function.

    .OUTPUTS
    The API-Response.

    .EXAMPLE

    Update properties on an existing PAT, like name, expiration and Scope:

    PS> $DevOpsPAT = @{
            authorizationId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
            TenantId        = "3d355765-67d9-47cd-9c7a-bf31179f56eb"
            Organization    = 'oliver-hammer'
            Name            = "Changed Name via API"
            Scope          = 'vso.code_full', 'vso.code_status'
            HoursValid      = 2
        }

    PS> Update-DevOpsPAT @DevOpsPAT


    .EXAMPLE

    Update a PAT token via pipeline:

    PS> $DevOpsPAT = @{
            TenantId        = "3d355765-67d9-47cd-9c7a-bf31179f56eb"
            Organization    = 'oliver-hammer'
            Name            = "Test"
            Scope          = 'vso.code_full', 'vso.code_status'
            HoursValid      = 2
        }

    PS> $DevOpsPAT = Get-DevOpsPAT @DevOpsPAT 

    PS> $DevOpsPAT = $DevOpsPAT | Update-DevOpsPAT -hoursvalid 10 -Name "Testing Bla"



    .LINK
        
#>
function Update-DevOpsPAT {

    [CmdletBinding()]
    param (
        # The unique Authorization ID identifing the PAT.
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [System.String]
        $authorizationId,

        # The AzureAd tenant id to wich the organization is connected to.
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [System.String]
        $TenantId,
        
        # The Organization in which the PAT shoul be created. Defaults to current Context.
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [System.String]
        $Organization,

        # The optional Name of the retrieved or newly created PAT.
        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('displayName')]
        [System.String]
        $Name,

        # A list of permission Scope for the PAT.
        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true
        )]
        [System.String[]]
        [ValidateScript(
            {
                $validScope = @(
                    'app_token', # <== Full Scope, everything enabled
                    
                    # Follows UI in DevOps-Portal
                    'vso.agentpools', 'vso.agentpools_manage', # Read | Read & Manage
                    'vso.analytics'
                    'vso.auditlog', 'vso.auditstreams_manage',
                    'vso.build', 'vso.build_execute' # Read | Read & Execute
                    'vso.code', 'vso.code_write', 'vso.code_full', 'vso.code_status',
                    'vso.connected_server', 
                    'vso.machinegroup_manage', # Deployment group
                    'vso.entitlements', 
                    'vso.environment_manage', 
                    'vso.extension.data', 'vso.extension.data_write',
                    'vso.extension', 'vso.extension_manage', 
                    'vso.graph', 'vso.graph_manage',
                    'vso.identity', 'vso.identity_manage',
                    'vso.gallery', 'vso.gallery_acquire', 'vso.gallery_publish', 'vso.gallery_manage',
                    'vso.memberentitlementmanagement', 'vso.memberentitlementmanagement_write',
                    'vso.notification', 'vso.notification_write', 'vso.notification_manage', 'vso.notification_diagnostics', 
                    'vso.packaging', 'vso.packaging_write', 'vso.packaging_manage',
                    'vso.pipelineresources_use', 'pipelineresources_manage',
                    'vso.project', 'vso.project_write', 'vso.project_manage',
                    'vso.threads_full',
                    'vso.release', 'release_execute', 'vso.release_manage'
                    'vso.securefiles_read', 'vso.securefiles_write', 'vso.securefiles_manage',
                    'vso.security_manage',
                    'vso.serviceendpoint', 'vso.serviceendpoint_query', 'vso.serviceendpoint_manage',
                    'vso.symbols', 'vso.symbols_write', 'vso.symbols_manage',
                    'vso.taskgroups_read', 'vso.taskgroups_write', 'vso.taskgroups_manage'
                    'vso.dashboards', 'vso.dashboards_manage', 
                    'vso.test', 'vso.test_write', 
                    'vso.tokenadministration', 
                    'vso.tokens',
                    'vso.profile', 'vso.profile_write',
                    'vso.variablegroups_read', 'vso.variablegroups_write', 'vso.variablegroups_manage',
                    'vso.wiki', 'vso.wiki_write', 
                    'vso.work', 'vso.work', 'work_full'
                )

                foreach ($scope in $_) {
                    if ($scope -notin $validScope) {
                        return $false
                    }
                }
                return $true
            },
            ErrorMessage = "Not a valid scope!"
        )]
        $Scope,

        # How many Hours the generated PAT will be valid.
        [Parameter(
            ValueFromPipelineByPropertyName = $true
        )]
        [System.Int32]
        $HoursValid = 8,

        [Parameter()]
        [switch]
        $AllOrgs,


        # When using pipes preserving the token accross the pipeline.
        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true
        )]
        [System.String]
        $Token,

        # When using pipes preserving the token accross the pipeline.
        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('filePath')]
        [System.String]
        $Path
    )

    BEGIN {}
    PROCESS {

        $accessToken = (Get-AzAccessToken -ResourceUrl '499b84ac-1321-427f-aa17-267ca6975798' -TenantId $TenantId).Token
        $Request = @{
            Method  = 'GET'
            URI     = "https://vssps.dev.azure.com/$Organization/_apis/tokens/pats/?authorizationId=$authorizationId&api-version=7.0-preview.1"
            Headers = @{
                'Authorization' = "Bearer $accessToken"
                'Content-Type'  = 'application/json; charset=utf-8'    
            }
        }
        $ExistingPAT = Invoke-RestMethod @Request | Select-Object -ExpandProperty patToken
    


        $accessToken = (Get-AzAccessToken -ResourceUrl '499b84ac-1321-427f-aa17-267ca6975798' -TenantId $TenantId).Token
        $Request = @{
            METHOD  = 'PUT'
            URI     = "https://vssps.dev.azure.com/$Organization/_apis/tokens/pats?api-version=7.0-preview.1"
            Headers = @{
                'Authorization' = "Bearer $accessToken"
                'Content-Type'  = 'application/json; charset=utf-8'    
            }
            Body    = @{
                displayName     = [System.String]::IsNullOrEmpty($Name) ? $ExistingPAT.Name : $Name # Rename existing PAT
                scope           = $null -NE $Scope  ? ($Scope -join ' ') : $ExistingPAT.scope # Update Scope of existing PAT
                validTo         = ([DateTime]::now).AddHours($HoursValid) # Extend Existing PAT
                authorizationId = $authorizationId 
                allOrgs         = $AllOrgs -EQ $true
            } | ConvertTo-Json
        }

        $PATdata = Invoke-RestMethod @Request 
        | Select-Object -ExpandProperty patToken
        | Add-Member -MemberType NoteProperty -Name tenantId -Value $TenantId -PassThru
        | Add-Member -MemberType NoteProperty -Name organization -Value $Organization -PassThru
        | Add-Member -MemberType NoteProperty -Name token -Value $Token -PassThru -Force

        $PATdata = [PSCustomObject]@{
            displayName     = $PATdata.displayName
            organization    = $PATdata.organization
            tenantId        = $PATdata.tenantId
            token           = $PATdata.token
            authorizationId = $PATdata.authorizationId
            scope           = $PATdata.scope.split(' ') 
            validFrom       = $PATdata.validFrom
            validTo         = $PATdata.validTo
            targetAccounts  = $PATdata.targetAccounts
        } 

        if ([System.String]::IsNullOrEmpty($Path)) {
            return $PATdata
        }
        else {
            return $PATdata | Save-DevOpsPAT -Path $Path
        }

    }
    END {}

}