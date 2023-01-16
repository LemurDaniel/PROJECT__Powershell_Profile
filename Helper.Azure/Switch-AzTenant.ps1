
function Switch-AzTenant {

    param (
        # Parameter help description
        [Parameter(Mandatory = $true)]
        [ValidateSet([AzTenant])]
        [System.String]
        $Tennant,

        [Parameter()]
        [switch]
        $NoDissconnect = $false
    )
    
    if (!$NoDissconnect) {
        Disconnect-AzAccount
    }
   
    $tenantId = [AzTenant]::GetByName($Tennant).id
    Connect-AzAccount -Tenant $tenantId
    az login --tenant $tenantId
}