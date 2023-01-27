
<#
    .SYNOPSIS
    Adds a new Sprint-Increment to the Project.

    .DESCRIPTION
    Adds a new Sprint-Increment to the Project and associates it with the specified team.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Response of the Request containing the new iteration.


    .EXAMPLE

    Add-SprintIncrement:

    PS> Add-SprintIncrement 'DC Azure Migration'


    .LINK
        
#>
function Add-SprintIncrement {

    [CmdletBinding()]
    param(
        [parameter()]
        [System.String]
        $Team = 'DC Azure Migration'
    )

    # Get Latest Sprint Iteration.
    $LatesSprint = Get-SprintIterations -Refresh | Sort-Object -Property { $_.attributes.startDate } | Select-Object -Last 1

    $lastFinishDate = [System.DateTime]$LatesSprint.attributes.finishDate
   

    # Get WeekOfyear for date with fancy .NET System.Globalization.Calendar
    $cultureInfo = [System.Globalization.CultureInfo]::GetCultureInfo('de-DE')
    $CalendarWeekRule = $cultureInfo.DateTimeFormat.CalendarWeekRule
    $firstWeekDay = [System.DayOfWeek]::Monday # <== Gets interpreted as first day of a Week.

    # Calculates difference between current day and next Monday, via DayOfWeek-enum.
    $difference = ($lastFinishDate.DayOfWeek + 7 - $firstWeekDay) % 7
    $startOfNextWeek = $lastFinishDate.AddDays(-$difference + 7)
    $WeekOfYear = $cultureInfo.Calendar.GetWeekOfYear($startOfNextWeek, $CalendarWeekRule, $firstWeekDay)



    $SprintIteration = @{
        Name         = [System.String]::Format('{0}-{1:00}and{2:00}', $startOfNextWeek.Year, $WeekOfYear, $WeekOfYear + 1)
        StartDate    = $startOfNextWeek
        finishDate   = $startOfNextWeek.AddDays(11)
        Team         = $Team 
    }

    return New-SprintIteration @SprintIteration

}
