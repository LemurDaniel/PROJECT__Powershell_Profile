function Search-AzFunctionAppSettings {

    [Alias('FAConf')]
    param (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $FunctionAppName
    )

    $FunctionApp = Search-AzFunctionApp -FunctionAppName $FunctionAppName
    if (!$FunctionApp) {
        throw 'Function App Not Found'
    }

    $Request = @{
        Method              = 'POST'
        Scope               = $FunctionApp.ResourceId
        API                 = '/config/appsettings/list?api-version=2021-02-01'
        noTopLevelProvider = $true
    }
    return Invoke-AzureRest @Request -return 'properties'
}