
<#
    .SYNOPSIS
    Executes kubectl logs for a deployment in the cluster.

    .DESCRIPTION
    Executes kubectl logs for a deployment in the cluster.
    With follow switches to another restarting pod on termination.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .EXAMPLE

    Follow logs with timestamps for the first pod in a deployment in the current namespace:

    PS> Read-K8SLogs <autcompleted_deployment> -Follow -Timestamps

    .EXAMPLE

    Follow logs with timestamps for a specific container in the first pod in a deployment in the current namespace:

    PS> Read-K8SLogs <autcompleted_pod> <autocompleted_container> -Follow -Timestamps

    .EXAMPLE

     Follow logs with timestamps for the first pod in a deployment in another namespace:

    PS> Read-K8SLogs -n <autocompleted_namespace> <autcompleted_deployment> -Follow -Timestamps

    .EXAMPLE

    Follow logs with timestamps for a specific container in a specific pod:

    PS> Read-K8SLogs <autcompleted_pod> <autocompleted_container> -Follow -Timestamps

    .LINK
        
#>



function Read-K8SLogs {

    [Alias('k8s-logs')]
    [CmdletBinding(
        DefaultParameterSetName = "Deployment"
    )]
    param (
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
            ErrorMessage = "Not a valid resource kind for the current cluster."
        )]
        $Deployment,

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
        [Alias('p')]
        $Pod,

        [Parameter(
            Position = 1,
            Mandatory = $false
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = @()
                if ($fakeBoundParameters.containsKey('Pod')) {
                    $pods = Get-K8SResources -Namespace $fakeBoundParameters['Namespace'] -Kind Pod 
                    | Where-Object { $_.metadata.name -EQ $fakeBoundParameters['Pod'] }

                    $validValues += $pods.spec.containers.name
                    $validValues += $pods.spec.initContainers.name
                }
                elseif ($fakeBoundParameters.containsKey('Deployment')) {
                    $deployments = Get-K8SResources -Namespace $fakeBoundParameters['Namespace'] -Kind Deployment 
                    | Where-Object { $_.metadata.name -EQ $fakeBoundParameters['Deployment'] }

                    $validValues += $deployments.spec.template.spec.containers.name
                    $validValues += $deployments.spec.template.spec.initContainers.name
                }
                
                $validValues 
                | Where-Object -Property Length -GT 0
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [Alias('c')]
        $Container,

        [Parameter(
            Position = 2,
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
            }
        )]
        $Namespace,

        # Switch to list logs of a previous instance of the container in the pod
        [Parameter()]
        [switch]
        $Previous,

        # Follow logs live
        [Parameter()]
        [switch]
        $Follow,

        # Include timestamps on each line
        [Parameter()]
        [switch]
        $Timestamps
    )

    if ([System.String]::IsNullOrEmpty($Namespace)) {
        $Namespace = (Get-K8SContexts -Current).namespace
    }

    [System.String[]]$options = $()
    if ($Follow) {
        $options += "--follow"
    }
    if ($Previous) {
        $options += "--previous"
    }
    if ($Timestamps) {
        $options += "--timestamps"
    }
    if ($PSBoundParameters.ContainsKey('container')) {
        $options += '--container'
        $options += $container
    }

    if ($PSBoundParameters.ContainsKey('Deployment')) {
     
        $inputKeyEvent = $null
        do {

            $deploymentData = Get-K8SResources -Type Deployment -Namespace $Namespace
            | Select-K8SResource metadata.name EQ $Deployment
        
            $deploymentPod = Get-K8SResources -Namespace $Namespace -Kind Pod
            | Select-K8SLabels $deploymentData.spec.selector
            | Select-Object -ExpandProperty metadata
            | Select-Object -ExpandProperty name
            | Select-Object -First 1

            # kubectl logs $options --namespace $Namespace --selector ($matchLabels -join ',')
            Write-Host -ForegroundColor Magenta "Found Pod '$($deploymentPod)'."
            kubectl logs $options --namespace $Namespace $deploymentPod

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

    }
    elseif ($PSBoundParameters.ContainsKey('Pod')) {

        kubectl logs $options --namespace $Namespace $Pod

    }
}