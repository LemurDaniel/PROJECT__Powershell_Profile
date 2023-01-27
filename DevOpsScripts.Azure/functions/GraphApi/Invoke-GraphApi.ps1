
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
        [ValidateSet('users', 'me')]
        $ApiResource,

        [Parameter()]
        [System.String]
        $ApiEndpoint
    )

    $uri = "https://graph.microsoft.com/v1.0/$(Join-Path -Path $ApiResource -ChildPath $ApiEndpoint)"
    Write-Host $uri
    $response = Invoke-AzRestMethod -Uri $uri -Verbose


    return ($response.Content | ConvertFrom-Json -Depth 8)
  
}