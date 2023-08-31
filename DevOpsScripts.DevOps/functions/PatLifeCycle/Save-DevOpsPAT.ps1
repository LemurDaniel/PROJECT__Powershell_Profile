
<#
    .SYNOPSIS
    Save a DevOps PAT securly on the disk.

    .DESCRIPTION
    Save a DevOps PAT securly on the disk.
    The token ist saved securly on the disk with SercureString using the underlying Windows Data Protection API.

    .INPUTS
    You can pipe PAT-responses into the function.

    .OUTPUTS
    TODO


    .EXAMPLE

    Create and save a PAT token via pipeline:

    PS> $DevOpsPAT = @{
            TenantId        = "3d355765-67d9-47cd-9c7a-bf31179f56eb"
            Organization    = 'oliver-hammer'
            Name            = "Test"
            Scope          = 'vso.code_full', 'vso.code_status'
            HoursValid      = 2
        }

    PS> $DevOpsPAT = Get-DevOpsPAT @DevOpsPAT 

    PS> $DevOpsPAT | Update-DevOpsPAT -hoursvalid 10 -Name "Testing Bla"



    .LINK
        
#>
function Save-DevOpsPAT {

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
        [System.String]
        $validTo,

        # When using pipes preserving the token accross the pipeline.
        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true
        )]
        [System.String]
        $validFrom,

        # When using pipes preserving the token accross the pipeline.
        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true
        )]
        [System.String[]]
        $targetAccounts,


        # Path where to save the PAT Will be saved encrypted
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

        if ($Path.EndsWith('.pat')) {
            $null = Remove-Item -Path $Path -ErrorAction SilentlyContinue
            $Path = ($Path.split('\') | Select-Object -SkipLast 1) -join '/'
        }


        $Path = [System.String]::IsNullOrEmpty($Path) ? "$env:USERPROFILE/azureDevOps" : $Path
        if (!(Test-Path -Path $Path)) {
            $null = New-Item -ItemType Directory -Path $Path
        }
    
        $Path = Get-Item -Path $Path | Select-Object -ExpandProperty FullName
    
        # Convert all data to an identifier. For the same parameter inputs, the same pat will be retrieved
        $bytes = [System.Text.Encoding]::GetEncoding('UTF-8').GetBytes(@(
            ($Scope | Sort-Object | ForEach-Object { $_ }), $name, $TenantId, $Organization
            )) 
        $identifier = "$([System.Convert]::ToHexString($bytes)).pat"
        $fullPathToFile = Join-Path -Path $Path -ChildPath $identifier

        $PATdata = [PSCustomObject]@{
            displayName     = $Name
            organization    = $Organization
            tenantId        = $TenantId
            token           = $token
            authorizationId = $authorizationId
            scope           = $Scope 
            validFrom       = $validFrom
            validTo         = $validTo
            targetAccounts  = $targetAccounts
            filePath        = $fullPathToFile
        } 
        
        $PATdata  
        | ConvertTo-Json
        | ConvertTo-SecureString -AsPlainText
        | ConvertFrom-SecureString
        | Out-File -FilePath $fullPathToFile 

        return $PATdata 
    }
    END {}

}