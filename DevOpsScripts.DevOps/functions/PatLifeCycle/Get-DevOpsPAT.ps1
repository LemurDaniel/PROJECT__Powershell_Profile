
<#
    .SYNOPSIS
    Retrieves an PAT-Token with an ID and a scope. If as same token has been created and not expired, will return it again.

    .DESCRIPTION
    Retrieves an PAT-Token with an ID and a scope. If as same token has been created and not expired, will return it again.
    The token ist saved securly on the disk with SercureString using the underlying Windows Data Protection API.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    TODO


    .EXAMPLE

    Get a either saved PAT-Token or generate a new one to access repositories:

    PS> $DevOpsPAT = @{
            TenantId     = "3d355765-67d9-47cd-9c7a-bf31179f56eb"
            Organization = 'oliver-hammer'
            Name         = "Testing PAT"
            HoursValid   = 0
            Scopes       = 'vso.code_full', 'vso.code_status'
            path         = "./pats"
        }

    PS> Get-DevOpsPAT @DevOpsPAT -Verbose


    .LINK
        
#>

function Get-DevOpsPAT {
    param (
        # The AzureAd tenant id to wich the organization is connected to.
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $TenantId,
        
        # The Organization in which the PAT shoul be created. Defaults to current Context.
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $Organization,

        # The optional Name of the retrieved or newly created PAT.
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $Name,

        # A list of permission scopes for the PAT.
        [Parameter(
            Mandatory = $true
        )]
        [System.String[]]
        [ValidateScript(
            {
                $validScopes = @(
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
                    if ($scope -notin $validScopes) {
                        return $false
                    }
                }
                return $true
            },
            ErrorMessage = "Not a valid scope!"
        )]
        $Scopes,

        # How many Hours the generated PAT will be valid.
        [Parameter()]
        [System.Int32]
        $HoursValid = 8,

        [Parameter()]
        [switch]
        $AllOrgs,



        # Path where to save the PAT. Will be saved encrypted
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Path,

        # Optional Parameter to return null if not PAT is found or expired, instead of creating a new one.
        [Parameter()]
        [switch]
        $OnlyRead
    )

    

    $Path = [System.String]::IsNullOrEmpty($Path) ? "$env:USERPROFILE/azureDevOps" : $Path
    if (!(Test-Path -Path $Path)) {
        $null = New-Item -ItemType Directory -Path $Path
    }


    # Convert all data to an identifier. For the same parameter inputs, the same pat will be retrieved
    $bytes = [System.Text.Encoding]::GetEncoding('UTF-8').GetBytes(@(
        ($PatScopes | Sort-Object | ForEach-Object { $_ }), $name, $TenantId, $Organization
        )) 
    $identifier = "$([System.Convert]::ToHexString($bytes)).pat"
    $fullPathToFile = Join-Path -Path $Path -ChildPath $identifier
    

    $DevOpsPATdata = Get-Content -Path $fullPathToFile  -ErrorAction SilentlyContinue 
    | ConvertTo-SecureString -ErrorAction SilentlyContinue 
    | ConvertFrom-SecureString -AsPlainText  -ErrorAction SilentlyContinue 
    | ConvertFrom-Json  -ErrorAction SilentlyContinue 
    

    if ($null -EQ $DevOpsPATdata -OR $DevOpsPATdata.validTo -LT [System.DateTime]::Now.ToUniversalTime()) {

        if ($OnlyRead) {
            return $null
        }

        Write-Verbose 'Generating new PAT'
        $PAT = @{
            TenantId     = $TenantId
            Organization = $Organization
            Name         = $Name
            HoursValid   = $HoursValid
            Scopes       = $Scopes
        }
        $DevOpsPATdata = New-DevOpsPAT @PAT

        $DevOpsPATdata 
        | ConvertTo-Json
        | ConvertTo-SecureString -AsPlainText
        | ConvertFrom-SecureString
        | Out-File $fullPathToFile

    }


    return $DevOpsPATdata
}