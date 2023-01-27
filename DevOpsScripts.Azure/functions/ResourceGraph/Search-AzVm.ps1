<#
    .SYNOPSIS
    Searches and returns a virutal machine from the Azure Resource Graph.

    .DESCRIPTION
    Searches and returns a virutal machine from the Azure Resource Graph.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Return a single or a list of AzVm Powershell objects.



    .LINK
        
#>

function Search-AzVm {
    param (
        # The Name the virtual machine must contain.
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $VirutalMachineName,

        # The number of vms to return.
        [Parameter(Mandatory = $false)]
        [System.int32]
        $take = 1,

        # Switch to open them in the Azure Portal.
        [Parameter(Mandatory = $false)]
        [switch]
        $open
    )
    
    return Search-AzResource -open:$open -take $take -ResourceName $VirutalMachineName -ResourceType 'microsoft.compute/virtualmachines'

}