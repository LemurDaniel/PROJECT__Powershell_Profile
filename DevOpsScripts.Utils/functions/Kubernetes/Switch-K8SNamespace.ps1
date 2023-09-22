


<#
    .SYNOPSIS
    Switch the namespace for the current AKS cluster in kubeconfig-file.

    .DESCRIPTION
    Switch the namespace for the current AKS cluster in kubeconfig-file.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .EXAMPLE

    Switch to a different namespace in the current cluster:

    PS> k8s-ns <autocompleted_namespace>


    .LINK
        
#>

function Switch-K8SNamespace {

    [Alias('k8s-ns')]
    param (
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

    $null = kubectl config set-context --current --namespace=$Namespace

    Write-Host -ForegroundColor Magenta "Switched to Namespace: '$Namespace'"
    
}

