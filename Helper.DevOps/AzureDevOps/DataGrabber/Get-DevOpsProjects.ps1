
function Get-DevOpsProjects {

    [cmdletbinding()]
    param()


    $RequestBlueprint = @{
        METHOD       = 'GET'
        SCOPE        = 'ORG'
        DOMAIN       = 'dev.azure'
        Property     = 'value'
    }

    $Cache = Get-AzureDevOpsCache -Type Project -Identifier 'all'
    if($Cache){
        return $Cache
    }
    
    $projects = Invoke-DevOpsRest @RequestBlueprint -API '_apis/projects?api-version=6.0'
    return Set-AzureDevOpsCache -Object $projects -Type Project -Identifier 'all'
}