function New-Workitem {


    param(
        [Parameter()]
        [ValidateSet(
            'Epic',
            'Feature',
            'User Story',
            'Task',
            'Bug',
            'Issue'
        )]
        [System.String]
        $Type = 'User Story',

        [parameter(Mandatory = $true)]
        [System.String]
        $Title,

        [Parameter()]
        [System.String]
        $Description = $null,

        [Parameter()]
        $Team = 'DC Azure Migration',
        [System.String]

        [Parameter()]
        [System.String]
        $AreaPath = 'DC Azure Migration'
    )



    $Request = @{
        Method = 'POST'
        SCOPE  = 'PROJ'
        API    = "/_apis/wit/workitems/`$${Type}?api-version=7.0"
        Body   = @(
            @{
                op    = 'add'
                path  = '/fields/System.Title'
                from  = $null
                value = $Title
            },
            @{
                op    = 'add'
                path  = '/fields/System.TeamProject'
                from  = $null
                value = $Team
            },
            @{
                op    = 'add'
                path  = '/fields/System.AreaPath'
                from  = $null
                value = $AreaPath
            },
            @{
                op    = 'add'
                path  = '/fields/System.Description'
                from  = $null
                value = $Description
            }
        )
    }

    $newWorkitem = Invoke-DevOpsRest @Request -ContentType 'application/json-patch+json'

    return $newWorkitem
}