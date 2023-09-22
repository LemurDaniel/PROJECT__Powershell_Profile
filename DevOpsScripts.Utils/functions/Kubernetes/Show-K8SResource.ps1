
<#
    .SYNOPSIS
    Same as kubectl describe, but with autocompletion

    .DESCRIPTION
    Same as kubectl describe, but with autocompletion


    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .LINK
        
#>



function Show-K8SResource {

    [Alias('k8s-describe')]
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

                $validValues = (Get-K8SResourceKind).aliases

                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-K8SResourceKind).aliases
            },
            ErrorMessage = "Not a valid resource kind in the cluster."
        )]
        $Kind,

        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = (Get-K8SResources -Namespace $fakeBoundParameters['Namespace'] -Kind $fakeBoundParameters['Kind']).metadata.name
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-K8SResources -Namespace $PSBoundParameters['Namespace'] -Kind $PSBoundParameters['Kind']).metadata.name
            },
            ErrorMessage = "Not a valid resource in the cluster."
        )]
        $Name
    )


    if ([System.String]::IsNullOrEmpty($Namespace)) {
        $Namespace = (Get-K8SContexts -Current).namespace
    }

    kubectl describe $Kind $Name --namespace $Namespace

}