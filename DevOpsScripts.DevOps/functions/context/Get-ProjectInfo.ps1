<#
    .SYNOPSIS
    Gets Project Info for the current project or a project specified in the current organization Context.

    .DESCRIPTION
    Gets Project Info for the current project or a project specified in the current organization Context.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Full Project info or a sub-Property of it if 'Property' is set.

    .EXAMPLE

    Get the Full Output of the current Project-Context.

    PS> Get-ProjectInfo

    .EXAMPLE

    Get the name of the current Project-Context.

    PS> Get-ProjectInfo 'name'

    .EXAMPLE

    Get the name of the 'BRZ365 Galaxy' Project-Context in the Current Organization-Context.

    PS> Get-ProjectInfo 'name' 'BRZ365 Galaxy'


    .EXAMPLE

    Get a Property in the Projectinfo:

    PS> Get-ProjectInfo 'autocompleted_property'
    PS> Get-ProjectInfo 'Teams.<autocomleted_property'

    .LINK
        
#>

function Get-ProjectInfo {

    [CmdletBinding()]
    param (

        # The name of the project, if not set default to the Current-Project-Context.
        [Parameter(
            Mandatory = $false,
            Position = 1
        )]
        [ValidateScript(
            { 
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-OrganizationInfo).projects.name
            },
            ErrorMessage = 'Please specify an correct Name.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-OrganizationInfo).projects.name
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Name,

        # The Property to return from the Project Context. If not set everything will be returned.
        [Alias('return')]
        [Parameter(
            Position = 0
        )]
        # Just for testing
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundsParameters)

                $object = Get-ProjectInfo -name $fakeBoundsParameters['Name']
                $autoCompletePrefix = @()

                if($wordToComplete.contains('.')){
                    # Won't work for thins like, 'System.Title' which is one Property with a dot in it.
                    $wordToComplete.split('.') | Select-Object -SkipLast 1 | ForEach-Object {
                        $autoCompletePrefix += $_
                        $object = $object."$_" | Select-Object -First 1
                    }
                }
                
                $validValues = $object.PSObject.Properties.Name | ForEach-Object { 
                    $autoCompletePrefix.Length -eq 0 ? $_ : "$($autoCompletePrefix -join '.').$_"
                }
                
                $validValues | `
                    Where-Object {
                        $_.toLower() -like ($wordToComplete.Length -lt 3 ? "$wordToComplete*" : "*$wordToComplete*").toLower() 
                    } | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Property,

        # Force API-Call and overwrite Cache
        [Parameter()]
        [switch]
        $Refresh
    )


    $ProjectName = ![System.String]::IsNullOrEmpty($Name) ? $Name : (Get-DevOpsContext -Project)
    $Organization = Get-DevOpsContext -Organization

    $Cache = Get-AzureDevOpsCache -Type Project -Identifier $ProjectName
    if (-not $Refresh -AND $Cache) {
        return $Cache | Get-Property -return $Property
    }


    ######################################
    # Get new stuff
    $RequestBlueprint = @{
        METHOD   = 'GET'
        Call     = 'ORG'
        DOMAIN   = 'dev.azure'
        Property = 'value'
    }

    $project = (Invoke-DevOpsRest @RequestBlueprint -API '_apis/projects?api-version=6.0') | Where-Object -Property name -EQ -Value $ProjectName 
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
    $basePath = [System.String]::IsNullOrEmpty($env:GIT_RepositoryPath) ? "$env:USERPROFILE\git\repos" : $env:GIT_RepositoryPath
    $projectPath = "$basePath\$($Organization.toUpper())\$($project.name)"
    if (!(Test-Path $projectPath)) {
        $null = New-Item -ItemType Directory -Path $projectPath
    }


    $project | Add-Member NoteProperty Projectpath $projectPath -Force
    $project.repositories | ForEach-Object {
        $_ | Add-Member NoteProperty Localpath (Join-Path "$projectPath" "$($_.name)") -Force
    }

    return Set-AzureDevOpsCache -Object $Project -Type Project -Identifier $ProjectName | Get-Property -return $Property
}