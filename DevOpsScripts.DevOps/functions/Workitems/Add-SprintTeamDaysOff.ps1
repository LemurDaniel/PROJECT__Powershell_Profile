
<#
    .SYNOPSIS
    Adds days off to the sprint increment for the whole team.

    .DESCRIPTION
    Adds days off to the sprint increment for the whole team.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    returns OK if successfull


    .EXAMPLE

    Add-SprintTeamDaysOff:

    PS> Add-SprintTeamDaysOff -IterationId "DC Azure Migration\2023-26and27" -Team 'DC Azure Migration' -DaysOff @(Get-Date 28.07.1995)


    .LINK
        
#>
function Add-SprintTeamDaysOff {

    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(Mandatory)]
        [System.String]
        $IterationId,

        [Parameter()]
        [datetime[]]
        $DaysOff = @(),

        [parameter()]
        [System.String]
        $Team = 'DC Azure Migration Team'
    )
    # get the sprint iteration, the capacity should be added
    $sprint = Get-SprintIterations | Where-Object -FilterScript { $IterationId -eq $_.id -or $IterationId -eq $_.path }

    $Request = @{
        METHOD = "PATCH"
        SCOPE  = "TEAM"
        team   = $Team
        API    = "_apis/work/teamsettings/iterations/{0}/teamdaysoff?api-version=6.0" -f $sprint.id
        Body   = @{
            daysOff      = @(($DaysOff | ForEach-Object {
                return @{
                    start = get-date -Date $_ -Format "yyyy-MM-ddTHH:mm:ss.fffZ" 
                    end = get-date -Date $_ -Format "yyyy-MM-ddTHH:mm:ss.fffZ" 
                }
            }))
        }
    }
    return Invoke-DevOpsRest @Request
}