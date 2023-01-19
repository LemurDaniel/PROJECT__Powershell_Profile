function Get-ProjectInfo {

    [CmdletBinding()]
    param (
        [Parameter()]
        [System.String]
        $Property,

        # Force API-Call and overwrite Cache
        [Parameter()]
        [switch]
        $refresh
    )


    $ProjectName = Get-DevOpsCurrentContext -Project
    $Organization = Get-DevOpsCurrentContext -Organization

    $Cache = Get-AzureDevOpsCache -Type Project -Identifier $ProjectName
    if (-not $refresh -AND $Cache) {
        return Get-Property -Object $Cache -Property $Property
    }


    # Get new stuff
    $RequestBlueprint = @{
        METHOD   = 'GET'
        Call     = 'ORG'
        DOMAIN   = 'dev.azure'
        Property = 'value'
    }

    $project = Invoke-DevOpsRest @RequestBlueprint -API '_apis/projects?api-version=6.0' | Where-Object -Property name -EQ -Value $ProjectName 
    if ($null -eq $project) {
        Throw "Project '$ProjectName' was not found in Current Organization: '$Organization'"
    }
   

    # Get Teams and Repositories associated with project.
    $project = $project | `
        Select-Object *, @{
        Name       = 'Teams'; 
        Expression = {  
            Invoke-DevOpsRest @RequestBlueprint -API "/_apis/projects/$($_.id)/teams?mine={true}&api-version=6.0" 
        }
    }, `
    @{
        Name       = 'Repositories'; 
        Expression = {  
            Invoke-DevOpsRest @RequestBlueprint -API "/$($_.id)/_apis/git/repositories?api-version=4.1"
        }
    }


    # Location where to download repositories.
    $basePath = [System.String]::IsNullOrEmpty($env:GIT_RepositoryPath) ? "$env:USERPROFILE\Documents\repos" : $env:GIT_RepositoryPath
    $projectPath = "$basePath\__$($Organization.toUpper())\$($project.name)"
    if (!(Test-Path $projectPath)) {
        $null = New-Item -ItemType Directory -Path $projectPath
    }


    $project | Add-Member NoteProperty Projectpath $projectPath -Force
    $project.repositories | ForEach-Object {
        $_ | Add-Member NoteProperty Localpath (Join-Path "$projectPath" "$($_.name)") -Force
    }

    Set-AzureDevOpsCache -Object $Project -Type Project -Identifier $ProjectName
    return Get-Property -Object $Project -Property $Property
}