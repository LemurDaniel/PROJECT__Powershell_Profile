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

    param ()

    # Remove Moved-Blocks from Terraform configuration.
    Edit-RegexOnFiles -regexQuery 'moved\s*\{[^\}]*\}'
  
}