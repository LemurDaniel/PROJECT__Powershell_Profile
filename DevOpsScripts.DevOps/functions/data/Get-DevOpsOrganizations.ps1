<#
    .SYNOPSIS
    Get all DevOps Organization the current User has Acces to.

    .DESCRIPTION
    Get all DevOps Organization the current User has Acces to.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Name of all Organizations connected to the Account.


    .EXAMPLE

    Gets all organizations conected to the user.

    PS> Get-DevOpsContext -Organization
    
    .LINK
        
#>
function Get-DevOpsOrganizations {

    [cmdletbinding()]
    param(
        [Parameter()]
        [switch]
        $Refresh
    )

    $Identifier = ((Get-AzContext).Account.id ?? "default")
    $Cache = Get-UtilsCache -Type Organization -Identifier $Identifier
    if ($Cache -AND !$Refresh) {
        return $Cache
    }



    # Organizations added via PAT.
    $Organizations = @()
    $filedata = Read-SecureStringFromFile -Identifier organizations.pat.all -AsHashtable
    if ($filedata) {
        $Organizations += $filedata.Keys | ForEach-Object { 
            @{ 
                accountId          = $null
                accountUri         = $null
                tenantId           = $null
                isPATauthenticated = $true
                accountName        = $_ 
            } 
        }
    }



    $Organizations += Get-AzTenant
    | Select-Object -Property Id, @{
        Name       = "accessToken"
        Expression = { 
            (Get-AzAccessToken -ResourceUrl '499b84ac-1321-427f-aa17-267ca6975798' -TenantId $_.Id).Token 
        }
    }
    # Using powershell -parallel instead of manually creating background-jobs
    | ForEach-Object -AsJob -Parallel {
        
        $tenantId = $_.Id
        $token = $_.accessToken
        $Request = @{        
            Method  = "GET"      
            Headers = @{            
                username       = $null        
                Authorization  = "Bearer $token"          
                'Content-Type' = 'application/x-www-form-urlencoded'      
            }        
            Uri     = "https://app.vssps.visualstudio.com/_apis/profile/profiles/me?details=False&api-version=7.0"
        }
        $publicAlias = Invoke-RestMethod @Request
        | Select-Object -ExpandProperty publicAlias


        $Request = @{        
            Method  = "GET"      
            Headers = @{            
                username       = $null        
                Authorization  = "Bearer $token"          
                'Content-Type' = 'application/x-www-form-urlencoded'      
            }        
            Uri     = "https://app.vssps.visualstudio.com/_apis/accounts?memberId=$publicAlias&api-version=7.0"
        }

        try {
            return Invoke-RestMethod @Request
            | Select-Object -ExpandProperty value
            | ForEach-Object {
                $_ | Add-Member NoteProperty isPATauthenticated $false
                $_ | Add-Member NoteProperty tenantId $tenantId -PassThru
                $_ | Add-Member NoteProperty publicAlias $publicAlias
            }
        }
        catch {
            return @()
        }
    }
    | Wait-Job | Receive-Job

    if (($Organizations | Measure-Object).Count -eq 0) {
        Throw "Couldnt find any DevOps Organizations associated with User: '$(Get-DevOpsUser 'displayName')' - '$(Get-DevOpsUser 'emailAddress')'"
    }

    return Set-UtilsCache -Object $Organizations -Type Organization -Identifier $Identifier -Alive (24*60*7)

}