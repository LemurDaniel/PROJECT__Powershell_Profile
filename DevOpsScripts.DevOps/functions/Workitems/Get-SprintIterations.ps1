
<#
    .SYNOPSIS
    Gets all Sprint-Iterations in the Current Project.

    .DESCRIPTION
    Gets all Sprint-Iterations in the Current Project.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    List of all Sprint-iterations in the Project or the most current one.


    .EXAMPLE

    Get List of Sprint Iterations:

    PS> Get-SprintIterations

    .EXAMPLE

    Get Most Current Sprint Iteration:

    PS> Get-SprintIterations -Current

    .LINK
        
#>
function Get-SprintIterations {

    [CmdletBinding()]
    param(
        # The name of the Project. Will default to current project context.
        [Parameter(
            Mandatory = $false,
            Position = 1
        )]   
        [ValidateScript(
            { 
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-DevOpsProjects).name
            },
            ErrorMessage = 'Please specify a correct Projectname.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-DevOpsProjects).name 
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Project,

        # Switch to only return the most current Sprint-Iteration.
        [Parameter()]
        [switch]
        $Current
    )

    $Request = @{
        Project = $Project
        Method  = 'GET'
        SCOPE   = 'PROJ'
        API     = '/_apis/work/teamsettings/iterations?api-version=7.0'
        Query   = $Current ? @{
            '$timeframe' = $Current ? 'current' : $Iteration
        } : $null
    }

    return Invoke-DevOpsRest @Request | Select-Object -ExpandProperty value
    #$iterations = Set-AzureDevOpsCache -Object $iterations -Type Iteration -Identifier (Get-ProjectInfo 'name')
}
