
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

    PS> Get-K8SResourceKind

    .EXAMPLE

    Get all available resource kinds in a specific cluster:

    PS> Get-K8SResourceKind <autocompleted_cluster>


    .LINK
        
#>


function Get-K8SResourceKind {
    param (
        [Parameter(
            Mandatory = $false,
            Position = 1
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
            Position = 0
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = @((Get-K8SResourceKind -Cluster $fakeBoundParameters['Cluster']).aliases | ForEach-Object { $_ })

                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-K8SResourceKind -Cluster $PSBoundParameters['Cluster']).aliases
            },
            ErrorMessage = "Not a valid resource kind."
        )]
        [Alias('k')]
        $Kind
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
            $kindData = [PSCustomObject]@{
                name       = $lineElements[0]
                shortname  = $lineElements[1]
                apiVersion = $lineElements[2]
                namespaced = [System.Boolean]::Parse($lineElements[3])
                kind       = $lineElements[4]
                aliases    = ([System.String[]] @($lineElements[4]) )
            } 

            if (![System.String]::IsNullOrEmpty($kindData.shortname)) {
                $kindData.aliases += $kindData.shortname
            }
            return $kindData
        } 
        | Set-UtilsCache -Identifier "k8s.$Cluster.resourceKinds.list" -Alive 5
    }

    if ($PSBoundParameters.ContainsKey('Kind')) {
        return $resourceKinds
        | Where-Object -Property aliases -Contains $Kind
    }
    else {
        return $resourceKinds
    }
}