function Get-GraphApiManager {
    param (
        [Parameter()]
        [System.String]
        $usermail
    )

    $userId = (Get-AzADUser -Mail $usermail).id
    return Invoke-GraphApi -ApiResource users -ApiEndpoint "$userId/manager"

}