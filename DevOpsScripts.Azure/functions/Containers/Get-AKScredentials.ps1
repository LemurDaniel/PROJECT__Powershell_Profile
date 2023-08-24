


<#
    .SYNOPSIS
    Get the Credentials for a AKS Cluster.

    .DESCRIPTION
    Get the Credentials for a AKS Cluster.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None



    .LINK
        
#>

function Get-AKScredentials {
    param (
        # The name of the context. Instead of Set-AzContext.
        [Parameter(
            Position = 1,
            Mandatory = $false
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = Get-AzContextsWrapper | Select-Object -ExpandProperty name
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        $Context,

        # The name of the cluster.
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                if ($fakeBoundParameters.containsKey('Context')) {
                    $AzContext = Get-AzContextsWrapper 
                    | Where-Object -Property name -EQ $fakeBoundParameters["Context"]
                    | Select-Object -ExpandProperty azContext
                }

                $validValues = Get-AzAksCluster -AzContext $AzContext
                | Select-Object -ExpandProperty Name
        
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        $Name

    )

    $AzContext = Get-AzContextsWrapper 
    | Where-Object -Property name -EQ $Context
    | Select-Object -ExpandProperty azContext

    # NOTE to Future: Will not work when same named clusters are in different resource groups 
    $AksCluster = Get-AzAksCluster -AzContext $AzContext
    | Where-Object -Property Name -EQ $Name

    Write-Host
    Write-Host -ForegroundColor Magenta "Found '$($AksCluster.Name)' in '$($AksCluster.ResourceGroupName)' "
    Import-AzAksCredential -ResourceGroupName $AksCluster.ResourceGroupName -Name $AksCluster.Name -AzContext $AzContext
}

