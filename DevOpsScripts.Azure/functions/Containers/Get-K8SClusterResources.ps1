
<#
    .SYNOPSIS
    Get a list of all k8s non-namespaced resources of a certain kind.

    .DESCRIPTION
    Get a list of all k8s non-namespaced resources of a certain kind.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Get all namespaces in the current cluster:

    PS> Get-K8SClusterResources Namespace


    .EXAMPLE

    Get all namespaces in a specific cluster:

    PS> Get-K8SClusterResources -c <autocompleted_cluster> Namespace


    .EXAMPLE

    Get the name of all namespaces in a specific cluster:

    PS> Get-K8SClusterResources -c <autocompleted_cluster> Namespace metadata.name

    PS> (Get-K8SClusterResources -c <autocompleted_cluster> Namespace).metadata.name

    .LINK
        
#>




function Get-K8SClusterResources {

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

                $validValues = (Get-K8SResourceKinds | Where-Object -Property namespaced -EQ $false).kind
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-K8SResourceKinds | Where-Object -Property namespaced -EQ $false).kind
            },
            ErrorMessage = "Not a valid resource kind for the current cluster."
        )]
        [Alias('Type', 'k')]
        $Kind,

        [Parameter(
            Mandatory = $false,
            Position = 2
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
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-K8SContexts).name
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
        $Attribute
    )

    if ([System.String]::IsNullOrEmpty($Cluster)) {
        $Cluster = (Get-K8SContexts -Current).name
    }

    $resourceList = Get-UtilsCache -Identifier "k8s.$Cluster.$Kind.list"

    if ($null -EQ $resourceList) {
        $resourceList = Kubectl get $Kind --context $Cluster -o JSON 
        | ConvertFrom-Json -Depth 99
        | Select-Object -ExpandProperty items
        | Set-UtilsCache -Identifier "k8s.$Cluster.$Kind.list" -AliveMilli 3000
    }

    if ($PSBoundParameters.ContainsKey('Attribute')) {
        $Attribute -split '\.(?![^\[]*])' 
        | ForEach-Object {
            $resourceList = $resourceList | Select-Object -ExpandProperty $_
        } 
    }

    return $resourceList
}