<#
    .SYNOPSIS
    Remove any moved block in the terraform configuration files on the current path.

    .DESCRIPTION
    Remove any moved block in the terraform configuration files on the current path.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None.

    .LINK
        
#>

function Remove-MovedBlocks {

    param (
        [Parameter()]
        [System.String]
        $Path = $null
    )

    # Remove Moved-Blocks from Terraform configuration.
    Edit-RegexOnFiles -Confirm:$false -replacementPath $Path -regexQuery 'moved\s*\{[^\}]*\}' -regexOptions @(
        [System.Text.RegularExpressions.RegexOptions]::Multiline 
    ) 
  
}