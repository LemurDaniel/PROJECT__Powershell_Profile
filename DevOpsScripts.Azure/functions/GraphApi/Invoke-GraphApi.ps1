

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

function Get-GraphApiManager {
    param (
        [Parameter()]
        [System.String]
        $usermail
    )

    $userId = (Get-AzADUser -Mail $usermail).id
    return Invoke-GraphApi -ApiResource users -ApiEndpoint "$userId/manager"

}

function  Get-onPremisesExtensionAttributes {
    param (
        [Parameter()]
        [System.String]
        $usermail
    )

    $userId = (Get-AzADUser -Mail $usermail).id
    return Invoke-GraphApi -ApiResource users -ApiEndpoint "$userId/onPremisesExtensionAttributes"
  
}