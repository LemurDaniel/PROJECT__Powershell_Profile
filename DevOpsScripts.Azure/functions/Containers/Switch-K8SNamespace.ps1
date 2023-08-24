


<#
    .SYNOPSIS
    Switch the namespace for the current AKS cluster in kubeconfig-file.

    .DESCRIPTION
    Switch the namespace for the current AKS cluster in kubeconfig-file.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None



    .LINK
        
#>

function Switch-K8SNamespace {

    [Alias('k8s-ns')]
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

                $validValues = kubectl get namespace
                | Select-Object -Skip 1 
                | ForEach-Object { [regex]::Match($_, "^[^\s]*").Value }
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript({
                $_ -in (
                    kubectl get namespace
                    | Select-Object -Skip 1 
                    | ForEach-Object { [regex]::Match($_, "^[^\s]*").Value }
                )
            })]
        $Namespace
    )

    kubectl config set-context --current --namespace=$Namespace

    Write-Host -ForegroundColor Magenta "Switched to Namespace: '$Namespace'"
}

