
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

    [CmdletBinding(
        DefaultParameterSetName = "Pod"
    )]
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
            ParameterSetName = "Pod",
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
            ParameterSetName = "Deployment",
            Mandatory = $true,
            Position = 0
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = (Get-K8SResources -Namespace $fakeBoundParameters['Namespace'] -Kind Deployment).metadata.name
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-K8SResources -Namespace $PSBoundParameters['Namespace'] -Kind Deployment).metadata.name
            },
            ErrorMessage = "Not a valid pod in the cluster."
        )]
        [Alias('deploy', 'd')]
        $Deployment,

        [Parameter(
            Mandatory = $false,
            Position = 2
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = $null
                if ($fakeBoundParameters.containsKey('Pod')) {
                    $validValues = (
                        Get-K8SResources -Namespace $fakeBoundParameters['Namespace'] -Kind Pod 
                        | Where-Object { $_.metadata.name -EQ $fakeBoundParameters['Pod'] }
                    ).spec.containers.name
                }
                elseif ($fakeBoundParameters.containsKey('Deployment')) {
                    $validValues = (
                        Get-K8SResources -Namespace $fakeBoundParameters['Namespace'] -Kind Deployment 
                        | Where-Object { $_.metadata.name -EQ $fakeBoundParameters['Deployment'] }
                    ).spec.template.spec.containers.name
                }
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
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

    [System.String[]]$options = $('-i', '-t')



    if ($PSBoundParameters.ContainsKey('Pod')) {

        $podData = Get-K8SResources -Namespace $Namespace -Kind Pod
        | Select-K8SResource metadata.name EQ $Pod

        if ([System.String]::IsNullOrEmpty($Container)) {
            $Container = $podData.spec.containers.name | Select-Object -First 1
        }

        kubectl exec $options --namespace $Namespace $Pod -c $Container $Command

    }

    elseif ($PSBoundParameters.ContainsKey('Deployment')) {

        $deployData = Get-K8SResources -Namespace $Namespace -Kind Deployment
        | Select-K8SResource metadata.name EQ $Deployment

        if ([System.String]::IsNullOrEmpty($Container)) {
            $Container = $deployData.spec.template.spec.containers.name | Select-Object -First 1
        }

        $inputKeyEvent = $null
        do {
        
            $deploymentPod = Get-K8SResources -Namespace $Namespace -Kind Pod
            | Select-K8SResource metadata.name LIKE "$Deployment*"
            | Select-Object -ExpandProperty metadata
            | Select-Object -ExpandProperty name
            | Select-Object -First 1

            kubectl exec $options --namespace $Namespace $deploymentPod -c $Container $Command
        
            Write-Host -ForegroundColor Magenta "--------------------------------"
            Write-Host -ForegroundColor Magenta ""
            Write-Host -ForegroundColor Magenta "... Lost connection to '$($deploymentPod)'."
            Write-Host -ForegroundColor Magenta "... Press Esc to Exit"
            Write-Host

            $sleepSeconds = 5
            Write-Host -ForegroundColor Magenta "... Searching for another pod in deployment '$Namespace/$Deployment' after $sleepSeconds seconds"
            Start-Sleep -Seconds $sleepSeconds

            Write-Host -ForegroundColor Magenta ""
            Write-Host -ForegroundColor Magenta "--------------------------------"

            if ([System.Console]::KeyAvailable) {
                $inputKeyEvent = [System.Console]::ReadKey()
            }

        } while ($null -EQ $inputKeyEvent -AND $inputKeyEvent.Key -NE [System.ConsoleKey]::Escape)

        return $deploymentPods
    }

}