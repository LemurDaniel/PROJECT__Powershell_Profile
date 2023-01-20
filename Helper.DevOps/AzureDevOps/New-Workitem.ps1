function New-Workitem {
  param(
    [parameter(Mandatory = $true)]
    [string]
    $Title,
    [string[]]
    $Description = $null,
    [string]
    $Team = 'DC Azure Migration',
    [string]
    $AreaPath = 'DC Azure Migration',
    [ValidateSet(
      'Epic',
      'Feature',
      'User Story',
      'Task',
      'Bug',
      'Issue'
    )]
    [string]
    $Type = 'User Story'
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
      }
    )
  }

  if ($PSBoundParameters.Keys -contains 'Description' -and $null -ne $Description) {
    $Request.body += @{
      op    = 'add'
      path  = '/fields/System.Description'
      from  = $null
      value = $Description
    }
  }
  $newWorkitem = Invoke-DevOpsRest @Request -ContentType 'application/json-patch+json'

  return $newWorkitem
}