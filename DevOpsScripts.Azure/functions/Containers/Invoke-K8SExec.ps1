
<#
    .SYNOPSIS
    Invokes kubectl exec for an interactive shell in a pod

    .DESCRIPTION
    Invokes kubectl exec for an interactive shell in a pod


    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .EXAMPLE

    Get interactive bash shell for a pod in the cluster:

    PS> k8s-exec <autcompleted_pod> bash


    .EXAMPLE

    Get interactive bash shell for a specific container in a pod in the cluster:

    PS> k8s-exec <autcompleted_pod> -c <autocompleted_container> bash


    .EXAMPLE

    Get interactive bash shell for a pod in the cluster in another namespace:

    PS> k8s-exec -n <autocompleted_namespace> <autcompleted_pod> <command>


    .LINK
        
#>



function Invoke-K8SExec {

    [Alias('k8s-exec')]
    param (
        [Parameter(
            Position = 3,
            Mandatory = $false
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = (Get-K8SClusterResources -Type Namespace).metadata.name
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-K8SClusterResources -Type Namespace).metadata.name
            },
            ErrorMessage = "Not a valid namespace in the cluster"
        )]
        $Namespace,


        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = (Get-K8SResources -Namespace $fakeBoundParameters['Namespace'] -Kind Pod).metadata.name
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-K8SResources -Namespace $PSBoundParameters['Namespace'] -Kind Pod).metadata.name
            },
            ErrorMessage = "Not a valid pod in the cluster."
        )]
        $Pod,


        [Parameter(
            Mandatory = $false,
            Position = 2
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = Get-K8SResources -Namespace $fakeBoundParameters['Namespace'] -Type Pod 
                | Where-Object { $_.metadata.name -EQ $fakeBoundParameters['Pod'] }
                | Select-Object -ExpandProperty spec
                | Select-Object -ExpandProperty containers
                | Select-Object -ExpandProperty name
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        # TODO
        # [ValidateScript(
        #     {
        #         $_ -in (
        #             Get-K8SResources -Namespace $PSBoundParameters['Namespace'] -Kind Pod
        #             | Where-Object { $_.metadata.name -EQ $PSBoundParameters['Pod'] }
        #             | Select-Object -ExpandProperty spec
        #             | Select-Object -ExpandProperty containers
        #             | Select-Object -ExpandProperty name
        #         )
        #     },
        #     ErrorMessage = "Not a valid container name in the pod."
        # )]
        [Alias('c')]
        $Container,


        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [System.String]
        $Command
    )

    if ([System.String]::IsNullOrEmpty($Namespace)) {
        $Namespace = (Get-K8SContexts -Current).namespace
    }

    $podData = Get-K8SResources -Type Pod -Namespace $Namespace
    | Where-Object { $_.metadata.name -EQ $Pod }


    if ([System.String]::IsNullOrEmpty($Container)) {
        $Container = $podData.spec.containers.name | Select-Object -First 1
    }

    [System.String[]]$options = $('-i', '-t')
    kubectl exec $options --namespace $Namespace $Pod -c $Container $Command

}