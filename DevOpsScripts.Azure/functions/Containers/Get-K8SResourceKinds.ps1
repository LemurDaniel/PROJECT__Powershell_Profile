
<#
    .SYNOPSIS
    Get all available resource kinds in the current cluster.

    .DESCRIPTION
    Get all available resource kinds in the current cluster.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .EXAMPLE

    Get all available resource kinds in the current cluster:

    PS> Get-K8SResourceKinds

    .EXAMPLE

    Get all available resource kinds in a specific cluster:

    PS> Get-K8SResourceKinds <autocompleted_cluster>


    .LINK
        
#>


function Get-K8SResourceKinds {
    param (
        [Parameter(
            Mandatory = $false,
            Position = 0
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
        $Cluster
    )
    
    if ([System.String]::IsNullOrEmpty($Cluster)) {
        $Cluster = (Get-K8SContexts -Current).name
    }

    $resourceKinds = Get-UtilsCache -Identifier "k8s.$Cluster.resourceKinds.list"

    if ($null -EQ $resourceKinds) {

        $resourceKinds = kubectl api-resources --context $Cluster
        | Select-Object -Skip 1 
        | ForEach-Object { 
            $lineElements = $_ -Split '\s+'
            if ($lineElements.Count -LT 5) {
                $lineElements = $($lineElements[0], $null) + $lineElements[1..($lineElements.Count - 1)]
            }
            return [PSCustomObject]@{
                name       = $lineElements[0]
                shortname  = $lineElements[1]
                apiVersion = $lineElements[2]
                namespaced = [System.Boolean]::Parse($lineElements[3])
                kind       = $lineElements[4]
            } 
        } 
        | Set-UtilsCache -Identifier "k8s.$Cluster.resourceKinds.list" -Alive 5
    }

    return $resourceKinds
}