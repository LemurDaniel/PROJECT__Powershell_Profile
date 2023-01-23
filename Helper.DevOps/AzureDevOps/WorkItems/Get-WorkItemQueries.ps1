
function Get-WorkItemQueries {
    param (
        [Alias('return')]
        [Parameter()]
        [System.String]
        $Property
    )

    $Queries = Get-AzureDevOpsCache -Type Queries -Identifier 'all'

    if(!$Queries){
    $Request = @{
        Method = 'GET'
        Domain = 'dev.azure'
        Call   = 'Proj'
        API    = '/_apis/wit/queries?$depth=1&api-version=7.1-preview.2'
    }
    $response = Invoke-DevOpsRest @Request -return 'Value.Children'
    $Queries = Set-AzureDevOpsCache -Object $response -Type Queries -Identifier 'all' -Alive 10
}

return Get-Property -Object $Queries -Property $Property
}