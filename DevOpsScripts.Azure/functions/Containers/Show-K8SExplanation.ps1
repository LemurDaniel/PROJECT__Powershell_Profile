

<#

    .SYNOPSIS
    Similar to kubectl explain, but with autocomplete on each property segment.

    .DESCRIPTION
    Similar to kubectl explain, but with autocomplete on each property segment.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The kubectl output for the input

    .EXAMPLE

    Explain the container section of a Deployment:
    Tab invokes autocomplete on the current section

    PS> k8s-expl Deployment.spec.template.spec.containers

    .LINK
        
#>


function Show-K8SExplanation {

    [Alias('k8s-explain', 'k8s-expl')]
    param (
        [Parameter(
            Mandatory = $true
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = $null
                if (!$wordToComplete.contains('.')) {
                    $validValues = (Get-K8SResourceKind).kind
                }

                else {
                    $wordSegments = $wordToComplete.split('.')
                    $kind = $wordSegments[0]
                    $path = @()
                    $path += $kind

                    $propertyTree = Get-K8SKindPropertyTree -Kind $kind
                    $wordSegments = $wordSegments[1..($wordSegments.Count - 1)]
                    | Where-Object {
                        return ![System.String]::IsNullOrEmpty($_)
                    }

                    foreach ($segment in $wordSegments) {
                        if($null -NE $propertyTree."$segment") {
                            $propertyTree = $propertyTree."$segment"
                            $path += $segment
                        }
                    }

                    if ($propertyTree -isnot [PSCustomObject]) {
                        return $path -join '.'
                    }

                    $validValues = $propertyTree.PSObject.properties.name
                    | ForEach-Object {
                        $propertyPath = @()
                        $propertyPath += $path
                        $propertyPath += $_ 
                        return $propertyPath -join '.'
                    }
                }
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        $path
    )

    return kubectl explain $path
}