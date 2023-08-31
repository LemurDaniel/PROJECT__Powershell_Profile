
<#
    .SYNOPSIS
    Revoke an existing PAT by authorization ID.

    .DESCRIPTION
    Revoke an existing PAT by authorization ID.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    You can pipe PAT-responses into the function.

    .EXAMPLE

    Revoke an existing pat

    PS> $DevOpsPAT = @{
            authorizationId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
            TenantId        = "3d355765-67d9-47cd-9c7a-bf31179f56eb"
            Organization    = 'oliver-hammer'
        }

    PS> Revoke-DevOpsPAT @DevOpsPAT


    .EXAMPLE

    You can pipe PAT-responses into the function:

    PS> $DevOpsPAT = @{
            TenantId     = "3d355765-67d9-47cd-9c7a-bf31179f56eb"
            Organization = 'oliver-hammer'
            Name         = "Testing PAT"
            HoursValid   = 1
            Scope       = 'vso.code_full', 'vso.code_status'
        }

    PS> $DevOpsPAT = Get-DevOpsPAT @DevOpsPAT 

    PS> $DevOpsPAT | Revoke-DevOpsPAT

    .LINK
        
#>
function Revoke-DevOpsPAT {

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

        # When using pipes preserving the token accross the pipeline.
        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true
        )]
        [System.String]
        $filePath
    )

    BEGIN {}
    PROCESS {
        $token = (Get-AzAccessToken -ResourceUrl '499b84ac-1321-427f-aa17-267ca6975798' -TenantId $TenantId).Token
        $Request = @{
            METHOD  = 'DELETE'
            URI     = "https://vssps.dev.azure.com/$Organization/_apis/tokens/pats?authorizationId=$authorizationId&api-version=7.0-preview.1"
            Headers = @{
                'Authorization' = "Bearer $token"
                'Content-Type'  = 'application/json; charset=utf-8'    
            }
        }

        $null = Invoke-RestMethod @Request # Returns nothing
        if (![System.String]::IsNullOrEmpty($filePath)) {
            $null =  Remove-Item -Path $filePath -ErrorAction SilentlyContinue
        }
        return "Success"
    }
    END {}
}