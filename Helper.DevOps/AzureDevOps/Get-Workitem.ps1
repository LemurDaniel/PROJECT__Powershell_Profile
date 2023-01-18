function Get-WorkItem {
    param(
        [Parameter(Mandatory=$true)]
        $id
    )
    $Request = @{
        Method = 'GET'
        SCOPE  = 'PROJ'
        API    = "_apis/wit/workitems/${id}?api-version=7.0"
    }

    $workItem = (Invoke-DevOpsRest @Request).fields

    return $workItem
}
