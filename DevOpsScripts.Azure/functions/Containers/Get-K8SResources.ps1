
<#
    .SYNOPSIS
    Get a list of all k8s resources of a certain kind.

    .DESCRIPTION
    Get a list of all k8s resources of a certain kind.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Get all namespaces in the current cluster:

    PS> Get-K8SResources Namespace

    .EXAMPLE

    Get all namespaces in a specific cluster:

    PS> Get-K8SResources -Context <autocompleted_cluster> Namespace


    .EXAMPLE

    Get the name of all namespaces in a specific cluster:

    PS> Get-K8SResources -Context <autocompleted_cluster> Namespace metadata.name

    PS> (Get-K8SResources -Context <autocompleted_cluster> Namespace).metadata.name

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

                $validValues = (Get-K8SResourceKinds).kind
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-K8SResourceKinds).kind
            },
            ErrorMessage = "Not a valid resource kind for the current cluster."
        )]
        $Type,

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
                $_ -in (Get-K8SContexts).name
            },
            ErrorMessage = "Not a valid context in the kubeconfig file."
        )]
        $Context,

        [Parameter(
            Mandatory = $false,
            Position = 1
        )]
        [System.String]
        $Attribute
    )

    if(!$PSBoundParameters.ContainsKey('Context')) {
        $Context = (Get-K8SContexts -Current).name
    }

    $resourceList = Kubectl get $Type --context $Context -o JSON 
    | ConvertFrom-Json -Depth 99
    | Select-Object -ExpandProperty items

    if ($PSBoundParameters.ContainsKey('Attribute')) {
        $Attribute -split '\.(?![^\[]*])' 
        | ForEach-Object {
            $resourceList = $resourceList | Select-Object -ExpandProperty $_
        } 
    }

    return $resourceList
}