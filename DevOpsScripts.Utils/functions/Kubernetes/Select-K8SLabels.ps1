

<#
    .SYNOPSIS
    Filter return values from the function Get-K8SResources or Get-K8SClusterResources.

    .DESCRIPTION
    Filter return values from the function Get-K8SResources or Get-K8SClusterResources.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Get all pods for a deployment:

    PS> Get-K8SResources Pod | Select-K8SLables $deployment.spec.selector


    .LINK
        
#>


function Select-K8SLabels {

    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [System.Object]
        $Resource,

        [Parameter(            
            Position = 1,
            Mandatory = $true
        )]
        [System.Object[]]
        $Selector
    )


    BEGIN {
        $Selection = @()

        $matchingExpressions = @()

        if ($Selector.matchingExpressions) {
            $matchingExpressions += $Selector.$matchingExpressions
        }
        if ($Selector.matchLabels) {
            foreach ($label in $Selector.matchLabels.PSObject.properties) {
                $matchingExpressions += [PSCustomObject]@{
                    key      = $label.Name
                    operator = "In"
                    values   = [System.String[]]@($label.Value)
                }
            }
        }

    }

    PROCESS {

        $evaluation = $true

        foreach ($expression in $matchingExpressions) {

            switch ($expression.operator) {

                'In' { 
                    $selectionLabelValue = $Resource.metadata.labels."$($expression.key)"
                    $evaluation = $evaluation -AND ($selectionLabelValue -IN $expression.values)
                    break
                }

                'NotIn' { 
                    $selectionLabelValue = $Resource.metadata.labels."$($expression.key)"
                    $evaluation = $evaluation -AND ($selectionLabelValue -NOTIN $expression.values)
                    break
                }

                'Exists' { 
                    $selectionLabel = $Resource.PSObject.Properties
                    | Where-Object -Property Name -EQ $expression.Key
                    $evaluation = $evaluation -AND (Enull -NE $selectionLabel)
                    break
                }

                'DoesNotExist' { 
                    $selectionLabel = $Resource.PSObject.Properties
                    | Where-Object -Property Name -EQ $expression.Key
                    $evaluation = $evaluation -AND (Enull -EN $selectionLabel)
                    break
                }

                Default {
                    throw "'$_' Not Supported"
                }
            }

        }

        if ($evaluation) {
            $Selection += $Resource
        }
    }

    END {
        return $Selection
    }
}