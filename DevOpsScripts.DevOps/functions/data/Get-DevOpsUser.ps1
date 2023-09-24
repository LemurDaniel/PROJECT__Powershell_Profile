<#
    .SYNOPSIS
    Get Information about the current DevOps-User loggedin via Connect-AzAccount.

    .DESCRIPTION
    Get Information about the current DevOps-User loggedin via Connect-AzAccount.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Fullinformation of the current user or an attribute specified by Property.


    .EXAMPLE

    Gets the Current User in Azure DevOps:

    PS> Get-DevOpsUser

    
    .LINK
        
#>
function Get-DevOpsUser {

    [cmdletbinding()]
    param(
        [Parameter()]
        [System.String]
        $Property,

        [Parameter()]
        [switch]
        $Refresh
    )

    $Cache = Get-UtilsCache -Type User -Identifier 'devops'
    
    if ($Cache -AND $Cache.emailAddress.toLower() -eq (Get-AzContext).Account.Id.ToLower() -AND !$Refresh) {
        return Get-Property -Object $Cache -Property $Property
    }

    $Request = @{
        Method = 'GET'
        Call   = 'None'
        Domain = 'app.vssps.visualstudio'
        API    = '_apis/profile/profiles/me?api-version=7.0'
        Query  = @{
            details = $true
        }
    }
    $User = Invoke-DevOpsRest @Request
    $User | Add-Member NoteProperty publicAliases ([PSCustomObject]@{})

    $requestJobs = @()
    foreach ($tenant in (Get-AzTenant)) {
        $requestJobs += Start-Job -ArgumentList $tenant.Id {
            $tenantId = $args[0]
            $token = (Get-AzAccessToken -ResourceUrl '499b84ac-1321-427f-aa17-267ca6975798' -TenantId $tenantId).Token 
            $Request = @{        
                Method  = "GET"      
                Headers = @{            
                    username       = $null        
                    Authorization  = "Bearer $token"          
                    'Content-Type' = 'application/x-www-form-urlencoded'      
                }        
                Uri     = "https://app.vssps.visualstudio.com/_apis/profile/profiles/me?details=False&api-version=7.0"
            }
            $response = Invoke-RestMethod @Request
            return @{
                publicAlias = $response.publicAlias
                tenantId    = $tenantId
            }
        }
    }

    while ($requestJobs.Count -GT 0) {

        $unfinished = @()
        foreach ($job in $requestJobs) {
            if ($job.state -EQ [System.Management.Automation.JobState]::Running) {
                $unfinished += $job
            }
            else {
                $data = Receive-Job -Job $job
                $null = $User.publicAliases
                | Add-Member NoteProperty $data.tenantId $data.publicAlias
            }
        }
        $requestJobs = $unfinished
        Start-Sleep -Milliseconds 100
    }


    <#
        $Request = @{
            Method = 'GET'
            Call   = 'None'
            Domain = 'vssps.dev.azure'
            API    = '_apis/identities?api-version=6.0'
            Query  = @{
                filterValue     = $User.emailAddress
                queryMembership = 'None'
                searchFilter    = 'General'
            }
        }
        $Identity = Invoke-DevOpsRest @Request
        $User | Add-Member NoteProperty Identity $Identity.Value -Force


        $Request = @{
            Method = 'GET'
            Call   = 'None'
            Domain = 'vssps.dev.azure'
            API    = "_apis/graph/users/$($Identity.Value.subjectDescriptor)?api-version=5.0-preview.1"
        }
        $graphUser = Invoke-DevOpsRest @Request
        $User | Add-Member NoteProperty GraphUser $graphUser -Force
    #>

    $User 
    | Set-UtilsCache -Type User -Identifier 'devops' -Alive (24 * 60 * 7)
    | Get-Property -Property $Property

}