
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

        [Parameter(Mandatory = $true)]
        [ValidateSet('users', 'me')]
        $ApiResource,

        [Parameter()]
        [System.String]
        $ApiEndpoint,

        # The Property to return from the items. If null will return full Properties.
        [Alias('return')]
        [Parameter()]
        [System.String]
        $Property
    )

    $uri = "https://graph.microsoft.com/v1.0/$(Join-Path -Path $ApiResource -ChildPath $ApiEndpoint)"
    Write-Host $uri
    $response = Invoke-AzRestMethod -Method $Method -Uri $uri -Verbose


    $response = ($response.Content | ConvertFrom-Json -Depth 8)
    return Get-Property -Object $response -Property $Property
}