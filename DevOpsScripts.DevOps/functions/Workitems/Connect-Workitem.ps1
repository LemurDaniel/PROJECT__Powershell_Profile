<#
    .SYNOPSIS
    Creates a workitem  Relation between to workitems.

    .DESCRIPTION
    Creates a workitem  Relation between to workitems.

    .INPUTS
    None. You cannot pipe objects into Connect-Workitem

    .OUTPUTS
    The API-Respone with the first provided workitem and the new relation field.

    .EXAMPLE

    Create a Child Relation to a UserStory

    PS> $userStory = New-Workitem -Type 'User Story' -Title 'APITEST_UserStory'
    PS> $task = New-Workitem -Type Task -Title 'APITEST_Task'
    PS> Connect-Workitem -WorkItemId $userStory.id -linkElementUrl $task.url -RelationType Child


    .LINK
        
#>

function Connect-Workitem {

    param(
        # Workitem for Relation.
        [Parameter(
            Mandatory = $true
        )]
        [System.Int32]
        $WorkItemId,

        # LinkElement for Relation. Workitem url or artifact id, etc.
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $linkElementUrl,

        # Workitem Relation Type => Parent, Child, etc.
        [ValidateScript(
            {
                $_ -in (Get-WorkItemRelationTypes -All -return name)
            }
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = Get-WorkItemRelationTypes -All -return name
     
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $RelationType

    )
    $WorkItem
    $Request = @{
        METHOD      = 'PATCH'
        DOMAIN      = 'dev.azure'
        CALL        = 'PROJ'
        API         = "_apis/wit/workitems/$($WorkItemId)?api-version=4.1"
        ContentType = 'application/json-patch+json'
        Body        = @(
            @{
                op    = 'add'
                path  = '/relations/-'
                value = @{
                    rel        = Get-WorkItemRelationTypes $RelationType -return 'referenceName'
                    url        = $linkElementUrl
                    attributes = @{
                        name    = $RelationType
                        comment = "$((Get-DevOpsUser).displayName) created $RelationType"
                    }
                }
            }
        )
        AsArray     = $true
    }

    return Invoke-DevOpsRest @Request
}
