


<#
    .SYNOPSIS
    Switch the context for the current kubernetes cluster for kubectl.

    .DESCRIPTION
    Switch the context for the current kubernetes cluster for kubectl.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .EXAMPLE

    Switch to a cluster in the kubeconfig:

    PS> k8s-cluster <autocompleted_cluster>

    .EXAMPLE

    Switch to a cluster in the kubeconfig in a specific namespace:

    PS> k8s-cluster <autocompleted_cluster> <autocompleted_namespace>

    .LINK
        
#>

function Switch-K8SCluster {

    [Alias('k8s-cluster')]
    param (
        # The name of the context. Instead of Set-AzContext.
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = (Get-K8SContexts).cluster
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-K8SContexts).cluster
            }
        )]
        $Cluster,

        # Switch the namespace for the selected context
        [Parameter(
            Position = 1,
            Mandatory = $false
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
        
                $validValues = (Get-K8SClusterResources -Type Namespace -Cluster $fakeBoundParameters['Cluster']).metadata.name
                        
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-K8SClusterResources -Type Namespace -Cluster $PSBoundParameters['Cluster']).metadata.name
            }
        )]
        $Namespace
    )
  
    $null = kubectl config use-context $Cluster 
    
    if ($PSBoundParameters.ContainsKey('Namespace')) {
        $null = kubectl config set-context --current --namespace=$Namespace
    }
    else {
        $Namespace = (Get-K8SContexts -Current).namespace
    }

    Write-Host -ForegroundColor Magenta "Switched to Cluster: '$Cluster' with namespace: '$Namespace'"
}

