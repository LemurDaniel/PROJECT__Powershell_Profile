function Search-WorkItemInIteration {

    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true, 
            Position = 0,
            ParameterSetName = 'current'
        )]
        [Parameter(ParameterSetName = 'iterations')]
        [System.String[]]
        $SearchTags,

        [Parameter(
            Mandatory = $true,
            Position = 1,
            ParameterSetName = 'current'
        )]
        [switch]
        $Current,

        [Parameter(
            Mandatory = $true,
            Position = 1,
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

        [Parameter()]
        [switch]
        $Personal,

        [Parameter()]
        [switch]
        $Single
    )

    $TargetIteration = $Current ? (Get-SprintIterations -Current) : ((Get-SprintIterations) | Where-Object -Property name -EQ -Value $Iteration)
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
        
    if ($Personal) {
        $workItems = $workItems | Where-Object { $_.'System.AssignedTo'.uniqueName -like (Get-AzContext).Account.Id }
    }
    
    return Search-In $workItems -where 'System.Title' -is $SearchTags -Multiple:$(!$Single)
}
