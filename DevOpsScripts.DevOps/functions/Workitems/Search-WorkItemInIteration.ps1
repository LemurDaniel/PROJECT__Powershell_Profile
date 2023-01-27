<#
    .SYNOPSIS
    Searches a Worktime in an Sprint-Iteration.

    .DESCRIPTION
    Searches a Worktime in an Sprint-Iteration.

    .INPUTS
    None. You cannot pipe objects into Search-WorkitemInIteration

    .OUTPUTS
    System.PSCustomObject[] A single of List of workitems from DevOps-API, depending whether single switch is set.

    .EXAMPLE

    Get Workitme assigend to user in current iteration:

    PS> Search-WorkItemInIteration -Current 'update','provider' -Personal -single

    .EXAMPLE

    Get Single Workitmes assigend to user in specific iteration:

    PS> Search-WorkItemInIteration -Iteration '2023-04and05' -SearchTags 'update','provider' -Personal -single

    .EXAMPLE

    Get multiple Workitmes in specific iteration:

    PS> Search-WorkItemInIteration '2023-04and05' 'update','provider'

        
    .EXAMPLE

    Get multiple Workitmes in specific iteration of type task:

    PS> Search-WorkItemInIteration '2023-04and05' 'update','provider' 'task'

    .LINK
        
#>

function Search-WorkItemInIteration {

    [CmdletBinding()]
    param(
        # The Iteration to search in. Either Iteration or Current switch need to be set exclusivley.
        [Parameter(
            Mandatory = $false,
            Position = 0,
            ParameterSetName = 'iterations'
        )]
        [ValidateScript(
            { 
                $_ -in (Get-SprintIterations).name
            },
            ErrorMessage = 'Please specify an correct Iteration.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-SprintIterations).name
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Iteration,


        # Retrieves the Current Sprint iteration. Either Iteration or Current switch need to be set exclusivley.
        [Parameter(
            Position = 0,
            ParameterSetName = 'current'
        )]
        [switch]
        $Current,


        # Search Tags, for Querying workitems.
        [Parameter(
            Mandatory = $true, 
            Position = 1,
            ParameterSetName = 'current'
        )]
        [Parameter(
            Mandatory = $true, 
            Position = 1,
            ParameterSetName = 'iterations'
        )]
        [System.String[]]
        $SearchTags,


        # Type of workitem to retrieve.
        [Parameter(
            Position = 2
        )]
        [ValidateSet(
            'Epic',
            'Feature',
            'User Story',
            'Task',
            'Bug',
            'Issue',
            'Any'
        )]
        [System.String]
        $Type = 'Any',


        # Gets only workitmes assigned to the current loggied in user.
        [Parameter()]
        [switch]
        $Personal,

        # Retrieves only the first workitem with the most hits.
        [Parameter()]
        [switch]
        $Single,



        # The Property to return from the items. If null will return full Properties.
        [Alias('return')]
        [Parameter()]
        [System.String]
        $Property
    )

    $TargetIteration = $Current ? (Get-SprintIterations -Current) : ((Get-SprintIterations) | Where-Object -Property name -EQ -Value $Iteration)
    
    $workItems = Get-AzureDevOpsCache -Type WITSearch -Identifier "$($TargetIteration.id)"
    if (!$workItems) {
        $Request = @{
            Method = 'GET'
            SCOPE  = 'PROJ'
            API    = "/_apis/work/teamsettings/iterations/$($TargetIteration.id)/workitems?api-version=7.1-preview.1"
        }
        $workItems = Invoke-DevOpsRest @Request

        $Request = @{
            Method = 'POST'
            SCOPE  = 'PROJ'
            API    = '/_apis/wit/workitemsbatch?api-version=7.1-preview.1'
            Body   = @{
                ids    = $workItems.WorkItemRelations.target.id
                fields = @(
                    'System.Id',
                    'System.Title',
                    'System.AssignedTo',
                    'System.WorkItemType',
                    'System.Parent',
                    'System.PersonId',
                    'System.ProjectId',
                    'System.Reason',
                    'System.RelatedLinkCount',
                    'System.RelatedLinks',
                    'Microsoft.VSTS.Scheduling.RemainingWork'
                )
            }
        }

        $workItems = (Invoke-DevOpsRest @Request).value.fields
        $workItems = Set-AzureDevOpsCache -Object $workItems -Type WITSearch -Identifier "$($TargetIteration.id)" -Alive 10
    }


    if ($Personal) {
        $workItems = $workItems | Where-Object { $_.'System.AssignedTo'.uniqueName -like (Get-AzContext).Account.Id }
    }

    if ($Type -ne 'Any') {
        $workItems = $workItems | Where-Object -Property 'System.WorkItemType' -EQ -Value $Type
    }

    if (!$workItems) {
        return $null
    }
    
    return Search-In $workItems -where 'System.Title' -is $SearchTags -Multiple:$(!$Single) -return $Property
}
