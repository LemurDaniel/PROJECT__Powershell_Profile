
<#
    .SYNOPSIS
    Test if the current path is a git repository.

    .DESCRIPTION
    Test if the current path is a git repository.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    true / False


    .EXAMPLE

    Check if current Path is a Repository:

    PS> Test-IsRepository 


    .EXAMPLE

    Check if a certain Path is a Repository:

    PS> Test-IsRepository -Path '<C://...>'

    .LINK
        
#>
function Test-IsRepository {

    param (
        [Parameter()]
        [System.String]
        $path = '.'
    )
    
    $null = git -C $path rev-parse 2>$null
    return $?
}