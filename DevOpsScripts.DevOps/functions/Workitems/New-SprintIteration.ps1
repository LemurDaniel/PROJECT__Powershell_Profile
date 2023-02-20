
<#
    .SYNOPSIS
    Creates a new iteration in the Project.

    .DESCRIPTION
    Creates a new iteration in the Project without association to a team.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    API Respones with the new Iteration.


    .EXAMPLE

    Create a new Sprint Iteration

    PS> New-SprintIteration  -Name '2023-07and08' -StartDate ([DateTime]::Now) -DurationDays 12


    .LINK
        
#>

function New-SprintIteration {

    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(

        [parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [parameter(
            Mandatory = $true,
            ParameterSetName = 'duration'
        )]
        [parameter(
            Mandatory = $true,
            ParameterSetName = 'finishdate'
        )]
        [System.DateTime]
        $StartDate,



        [parameter(
            Mandatory = $true,
            ParameterSetName = 'finishdate'
        )]
        [parameter()]
        [System.DateTime]
        $FinishDate,

        [parameter(
            Mandatory = $false,
            ParameterSetName = 'duration'
        )]
        [parameter()]
        [System.int32]
        $DurationDays = 14,


        [parameter()]
        [System.String]
        $Team = 'DC Azure Migration'
    )

    # Create Iteration.
    $Request = @{
        Method = 'POST'
        SCOPE  = 'PROJ'
        #team   = 'DC Azure Migration Team'
        API    = '_apis/wit/classificationnodes/Iterations?api-version=5.0'
        Body   = @{
            name       = $Name
            attributes = @{
                startDate  = $StartDate
                finishDate = $null -eq $FinishDate ? $StartDate.AddDays($DurationDays) : $FinishDate
            }
        }
    }
    $Iteration = Invoke-DevOpsRest @Request 


    # Associate Iteration with Team-Sprints.
    $Request = @{
        Method = 'POST'
        SCOPE  = 'TEAM'
        team   = 'DC Azure Migration Team'
        API    = '/_apis/work/teamsettings/iterations?api-version=7.1-preview.1'
        Body   = @{
            id   = $Iteration.identifier
            name = $Iteration.name
            path = $Iteration.path
            url  = $Iteration.url

        }
    }
    return Invoke-DevOpsRest @Request 
}
