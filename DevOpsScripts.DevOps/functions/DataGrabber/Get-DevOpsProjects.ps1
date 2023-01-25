
function Get-DevOpsProjects {

    [cmdletbinding()]
    param()

    $Cache = Get-AzureDevOpsCache -Type Project -Identifier 'all'
    if ($Cache) {
        return $Cache
    }
    
    $RequestBlueprint = @{
        METHOD   = 'GET'
        SCOPE    = 'ORG'
        DOMAIN   = 'dev.azure'
        API      = '_apis/projects?api-version=6.0'
        Property = 'value'
    }
    $projects = Invoke-DevOpsRest @RequestBlueprint

    if (($projects | Measure-Object).Count -eq 0) {
        Throw "Couldnt find any DevOps Projects associated with User: '$(Get-CurrentUser 'displayName')' - '$(Get-CurrentUser 'emailAddress')'"
    }

    return Set-AzureDevOpsCache -Object $projects -Type Project -Identifier 'all'
}