function Get-AzureDevOpsCache {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Type,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Identifier
    )

    $Organization = Get-DevOpsCurrentContext -Organization
    return Get-UtilsCache -Type $Type -Identifier "$Organization.$Identifier"

}