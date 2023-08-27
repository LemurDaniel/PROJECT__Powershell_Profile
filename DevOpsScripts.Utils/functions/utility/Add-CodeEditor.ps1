

<#
    .SYNOPSIS
    Add a new code editor for opening with gitvc, etc.

    .DESCRIPTION
    Add a new code editor for opening with gitvc, etc.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS

#>


function Add-CodeEditor {

    param (
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $Name,

        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $CodeEditor
    )

    $editors = Read-SecureStringFromFile -Identifier git.codeeditors.all -AsHashTable
    $editors[$Name] = @{
        path = $CodeEditor
    }
    Save-SecureStringToFile -Identifier git.codeeditors.all -Object $editors

    return $editors
    
}