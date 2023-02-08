
<#
    .SYNOPSIS
    Invokes the Azure GraphApi.

    .DESCRIPTION
    Invokes the Azure GraphApi. TODO

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None



    .LINK
        
#>

function Invoke-GraphApi {
    param (        
        [Parameter(Mandatory = $true)]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $METHOD,

        [Parameter()]
        [System.String]
        $ApiEndpoint
    )

    $uri = "https://graph.microsoft.com/v1.0/$ApiEndpoint"
    Write-Verbose $uri
    $response = Invoke-AzRestMethod -Method $Method -Uri $uri -Verbose
    return ($response.Content | ConvertFrom-Json -Depth 8)
}