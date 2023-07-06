
<#
    .SYNOPSIS
    Adds a new member to a given Sprint-Increment in the Project.

    .DESCRIPTION
    Adds a new member to a given Sprint-Increment in the Project.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Response of the Request containing the new assigned member.


    .EXAMPLE

    Add-SprintMember:

    PS> Add-SprintMember -IterationId "DC Azure Migration\2023-26and27" -Team 'DC Azure Migration' -TeamMemberId cfa09702-f494-659a-8eef-33dcc7718190 


    .LINK
        
#>
function Add-SprintMember {

    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(Mandatory)]
        [System.String]
        $IterationId,

        [Parameter()]
        [guid]
        $TeamMemberId,

        [Parameter()]
        [ValidateSet("Unassigned", "Deployment", "Design", "Development", "Documentation", "Requirements", "Testing")]
        [string]
        $Activity = "Unassigned",

        [Parameter()]
        [UInt32]
        $CapacityPerDay = 0,

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
        API    = "_apis/work/teamsettings/iterations/{0}/capacities/{1}?api-version=6.0" -f $sprint.id, $TeamMemberId
        Body   = @{
            activities = @(
                @{
                    capacityPerDay = $CapacityPerDay
                    name           = $Activity
                }
            )
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