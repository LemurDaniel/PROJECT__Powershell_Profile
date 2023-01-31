<#
    .SYNOPSIS
    Searches and returns a App Settings for a Function App.

    .DESCRIPTION
    Searches and returns a App Settings for a Function App.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The App Settings of the found Function App.



    .LINK
        
#>
function Search-AzFunctionAppSettings {

    [Alias('FAConf')]
    param (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $FunctionAppName,

        # The Property to return from the items. If null will return full Properties.
        [Alias('return')]
        [Parameter()]
        [System.String]
        $Property
    )

    $FunctionApp = Search-AzFunctionApp -FunctionAppName $FunctionAppName -Take 1
    if (!$FunctionApp) {
        throw 'Function App Not Found'
    }

    $Request = @{
        Method              = 'POST'
        Scope               = $FunctionApp.ResourceId
        API                 = '/config/appsettings/list?api-version=2021-02-01'
    }
    $response = Invoke-AzureRest @Request -return 'properties'
    return Get-Property -Object $response -return $Property
}