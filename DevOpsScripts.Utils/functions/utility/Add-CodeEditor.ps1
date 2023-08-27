

<#
    .SYNOPSIS
    Add a new code editor for opening with gitvc, etc.

    .DESCRIPTION
    Add a new code editor for opening with gitvc, etc.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS

    .EXAMPLE

    Add code editor to a programm exposed via $env:PATH

    PS> Add-CodeEditor -Name "Visual Studio Code" -Path code

    .EXAMPLE

    Add code editor with full path to exe:

    PS> Add-CodeEditor -Name Atom -Path "$env:APPDATA\..\Local\atom\atom.exe"

#>

C:\Users\Daniel\AppData\Local\atom
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
        $Path
    )

    $editors = Get-CodeEditor -ListAvailable
    $editors[$Name] = @{
        name = $Name
        path = $Path
    }
    Save-SecureStringToFile -Identifier git.codeeditors.all -Object $editors

    return $editors
    
}