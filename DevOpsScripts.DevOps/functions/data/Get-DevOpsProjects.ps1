<#
    .SYNOPSIS
    Gets all DevOps Projects in the current Organization-Context.

    .DESCRIPTION
    Gets all DevOps Projects in the current Organization-Context.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    List of all DevOps Projects in the current Organization-Context.


    .EXAMPLE

    Gets all Names of the DevOps Projects in the curren Organization-Context.

    PS> Get-DevOpsProjects
    

    .LINK
        
#>
function Get-DevOpsProjects {

    [cmdletbinding()]
    param(
        # The name of the Organization to switch to. Will default to current Organization Context.
        [Parameter(
            Mandatory = $false
        )]
        [ValidateScript(
            { 
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-DevOpsOrganizations).accountName
            },
            ErrorMessage = 'Please specify an correct Name.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-DevOpsOrganizations).accountName
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Organization
    )

    $Cache = Get-AzureDevOpsCache -Type Project -Organization $Organization -Identifier 'all'
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
        Throw "Couldnt find any DevOps Projects associated with User: '$(Get-DevOpsUser 'displayName')' - '$(Get-DevOpsUser 'emailAddress')'"
    }

    return Set-AzureDevOpsCache -Object $projects -Type Project -Organization $Organization -Identifier 'all'
}