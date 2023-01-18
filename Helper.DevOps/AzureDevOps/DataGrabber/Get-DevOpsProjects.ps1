
function Get-DevOpsProjects {

    [cmdletbinding()]
    param(
        [Parameter()]
        [System.String]
        $Organization = "baugruppe"
    )


    $RequestBlueprint = @{
        METHOD       = 'GET'
        SCOPE        = 'ORG'
        DOMAIN       = 'dev.azure'
        Property     = 'value'
        Organization = $Organization
    }

    $Cache = Get-AzureDevOpsCache -Type Project -Identifier 'all' -Organization  $Organization
    $projects = Invoke-DevOpsRest @RequestBlueprint -API '_apis/projects?api-version=6.0'
    return Set-AzureDevOpsCache -Object $projects -Type Project -Identifier 'all' -Organization  $Organization
}