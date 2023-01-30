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
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [System.String[]]
        $VirutalMachineName,

        # The number of resources to return.
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'Take'
        )]
        [System.int32]
        $Take = 1,

        # Switch to return all results.
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'All'
        )]
        [switch]
        $All,

        # The Property to return from the items. If null will return full Properties.
        [Alias('return')]
        [Parameter()]
        [System.String]
        $Property,

        # Switch to open them in the Azure Portal.
        [Parameter(Mandatory = $false)]
        [switch]
        $Browser
    )
    
    return Search-AzResource -Browser:$Browser -Property $Property -Take ($All ? 999 : $Take) -ResourceName $VirutalMachineName -ResourceType 'microsoft.compute/virtualmachines'

}