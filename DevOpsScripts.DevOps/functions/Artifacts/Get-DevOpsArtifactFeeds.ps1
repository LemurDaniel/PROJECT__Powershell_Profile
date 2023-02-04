

function Get-DevOpsArtifactFeeds {

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true
        )]
        [ValidateSet(
            'Project',
            'Organization',
            'All'
        )]
        $Scope
    )

    $Request = @{
        METHOD = 'GET'
        DOMAIN = 'feeds.dev.azure'
        API    = '_apis/packaging/feeds?api-version=7.0'
    }

    $feeds = [System.Collections.ArrayList]::new()
    
    if($SCOPE -in @('Project', 'All')){
        $cachedProj = Get-AzureDevOpsCache -Type Feed -Identifier (Get-DevOpsContext -Project)
        if(!$cachedProj){

            $cachedProj = Invoke-DevOpsRest @Request -CALL PROJ | Select-Object -ExpandProperty value
            $cachedProj = Set-AzureDevOpsCache -Object $cachedProj -Type Feed -Identifier (Get-DevOpsContext -Project)
        }
        $null = $cachedProj | ForEach-Object { $feeds.Add($_) }
    }
    if($SCOPE -in @('Organization', 'All')){
        $cachedOrg = Get-AzureDevOpsCache -Type Feed -Identifier Orgscoped
        if(!$cachedOrg){
            $cachedOrg = Invoke-DevOpsRest @Request -CALL ORG | Select-Object -ExpandProperty value
            $cachedOrg = Set-AzureDevOpsCache -Object $cachedOrg -Type Feed -Identifier Orgscoped
        }
        $null = $cachedOrg | ForEach-Object { $feeds.Add($_) }
    }

    return $feeds
}