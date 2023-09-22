
<#
    .SYNOPSIS
    Get all available contexts in the current kubectl config.

    .DESCRIPTION
    Get all available contexts in the current kubectl config.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .LINK
        
#>


function Get-K8SContexts {
    param (
        [Parameter()]
        [switch]
        $Current
    )
    
    $contexts = kubectl config get-contexts
    | Select-Object -Skip 1 
    | ForEach-Object { 
        $lineElements = $_ -Split '\s+'
        return [PSCustomObject]@{
            current   = $lineElements[0].length -GT 0
            name      = $lineElements[1]
            cluster   = $lineElements[2]
            authinfo  = [System.Boolean]$lineElements[3]
            namespace = $lineElements[4]
        } 
    } 

    if($Current) {
        return $contexts 
        | Where-Object -Property current -EQ $true
    }
    else {
        return $contexts
    }
}