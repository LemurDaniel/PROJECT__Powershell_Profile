
<#
    .SYNOPSIS
    Get a list of all namespaced k8s resources of a certain kind.

    .DESCRIPTION
    Get a list of all namespaced k8s resources of a certain kind.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Get all deployment names in the current cluster:

    PS> Get-K8SResources Deployment

    .EXAMPLE

    Get all deployment names in a specific cluster:

    PS> Get-K8SResources -c <autocompleted_cluster> -n <autocompleted_namespace> Deployment


    .EXAMPLE

    Get the name of all namespaces in a specific cluster:

    PS> Get-K8SResources -c <autocompleted_cluster> -n <autocompleted_namespace> Deployment metadata.name

    PS> (Get-K8SResources -c <autocompleted_cluster> -n <autocompleted_namespace> Deployment).metadata.name

    .LINK
        
#>




function Get-K8SResources {

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = (Get-K8SResourceKind | Where-Object -Property namespaced -EQ $true).aliases
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-K8SResourceKind | Where-Object -Property namespaced -EQ $true).aliases
            },
            ErrorMessage = "Not a valid resource kind for the current cluster."
        )]
        [Alias('Type', 'k')]
        $Kind,

        [Parameter(
            Position = 2,
            Mandatory = $false
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = (Get-K8SClusterResources -Cluster $fakeBoundParameters['Cluster'] -Kind Namespace).metadata.name
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-K8SClusterResources -Cluster $PSBoundParameters['Cluster'] -Kind Namespace).metadata.name
            }
        )]
        [Alias('n')]
        $Namespace,

        [Parameter(
            Mandatory = $false,
            Position = 3
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = (Get-K8SContexts).name
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-K8SContexts).name
            },
            ErrorMessage = "Not a valid context in the kubeconfig file."
        )]
        [Alias('c')]
        $Cluster,

        [Parameter(
            Mandatory = $false,
            Position = 1
        )]
        [System.String]
        $Attribute,

        # Returns resources from all namespaces
        [Parameter()]
        [switch]
        $AllNamespaces
    )

    if ([System.String]::IsNullOrEmpty($Cluster)) {
        $Cluster = (Get-K8SContexts -Current).name
    }

    $options = @("--context", $Cluster)

    if ($AllNamespaces) {
        $Namespace = $null
        $options += "--all-namespaces"
    }
    elseif ([System.String]::IsNullOrEmpty($Namespace)) {
        $Namespace = (Get-K8SContexts -Current).namespace
        $options += "--namespace"
        $options += $Namespace
    }

    $resourceList = Get-UtilsCache -Identifier "k8s.$Cluster.$Kind.$Namespace.list"

    if ($null -EQ $resourceList) {
        $resourceList = Kubectl get $Kind $options -o JSON 
        | ConvertFrom-Json -Depth 99
        | Select-Object -ExpandProperty items
        | Set-UtilsCache -Identifier "k8s.$Cluster.$Kind.$Namespace.list" -AliveMilli 5000
    }

    if ($PSBoundParameters.ContainsKey('Attribute')) {
        $Attribute -split '\.(?![^\[]*])' 
        | ForEach-Object {
            $resourceList = $resourceList | Select-Object -ExpandProperty $_
        } 
    }

    return $resourceList
}