
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

     Follow logs with timestamps for the first pod in a deployment in another namespace:

    PS> Read-K8SLogs -n <autocompleted_namespace> <autcompleted_deployment> -Follow -Timestamps


    .LINK
        
#>



function Read-K8SLogs {

    [Alias('k8s-logs')]
    param (
        [Parameter(
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
            Position = 1,
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

    $deploymentData = Get-K8SResources -Type Deployment -Namespace $Namespace
    | Where-Object { $_.metadata.name -EQ $Deployment }

    # TODO selector failing with some deployments
    $matchLabels = $deploymentData.spec.selector.matchLabels.PSObject.Properties
    | ForEach-Object { "$($_.Name)=$($_.Value)" }

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

    if ($Follow) {
     
        $inputKeyEvent = $null
        do {
        
            $deploymentPod = Get-K8SResources -Namespace $Namespace -Kind Pod
            | Select-K8SResource metadata.name LIKE "$Deployment*"
            | Select-Object -ExpandProperty metadata
            | Select-Object -ExpandProperty name
            | Select-Object -First 1

            # kubectl logs $options --namespace $Namespace --selector ($matchLabels -join ',')
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
}