
function Set-AzureDevOpsCache {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $Object,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Type,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Identifier,

        [Parameter(Mandatory = $false)]
        [System.int32]
        $Alive = 7
    )

    $Organization = Get-DevOpsCurrentContext -Organization
    return Set-UtilsCache -Object $Object -Type $Type -Identifier "$Organization.$Identifier" -Alive $Alive

}