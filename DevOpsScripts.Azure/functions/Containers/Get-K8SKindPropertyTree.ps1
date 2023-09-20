

<#


<#

    .SYNOPSIS
    Returns the result from kubectl explain --recursive as a JSON-object.

    .DESCRIPTION
    Returns the result from kubectl explain --recursive as a JSON-object.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The JSON-Representation of the kubectl output


    .LINK
        
#>


function Get-K8SKindPropertyTree {

    param (
        [Parameter(
            Mandatory = $true
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = (Get-K8SResourceKind).kind
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-K8SResourceKind).kind
            },
            ErrorMessage = "Not a valid resource kind."
        )]
        $kind
    )
    
    $cache = Get-UtilsCache -Identifier "k8s.explain.$($kind.toLower())"
    if ($cache) {
        return $cache
    }

    $output = kubectl explain $kind --recursive

    $output = $output -join [System.Environment]::NewLine
    $output = $output.substring($output.IndexOf("FIELDS:"))
    $output = $output -split [System.Environment]::NewLine

    $stack = [System.Collections.Stack]::new()
    $object = [PSCustomObject]@{}
    $previousProperty = $null
    $indentation = 0
    foreach ($line in $output) {

        if ($line.Length -EQ 0) {
            continue;
        }
    
        $propertyName = [regex]::Matches($line, "\S+\s*")[0].Value?.Trim()
        $propertyType = [regex]::Matches($line, "\S+\s*")[1].Value?.Trim()
        $lineIndent = [regex]::Match($line, "^\s+").Length

        if ($lineIndent -GT $indentation) {
            $object | Add-Member NoteProperty $previousProperty ([PSCustomObject]@{}) -Force
            $indentation = $lineIndent
            $stack.Push($object)

            $object = $object."$previousProperty"
        }

        elseif ($lineIndent -LT $indentation) {
            for ($steps = ($indentation - $lineIndent) / 2; $steps -GT 0; $steps--) {
                $object = $stack.Pop()
            }
            $indentation = $lineIndent
        }

        $object | Add-Member NoteProperty $propertyName $propertyType

        $previousProperty = $propertyName

    }

    while ($stack.Count -GT 1) {
        $object = $stack.Pop()
    }

    return Set-UtilsCache -Identifier "k8s.explain.$kind" -Object $object -Alive 1440
}