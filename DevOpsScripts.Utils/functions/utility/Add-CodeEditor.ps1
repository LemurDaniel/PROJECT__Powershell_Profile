

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

    .EXAMPLE

    Add code editor with full path to exe and set as Default: (Otherwise use Switch-DefaultCodeEditor)

    PS> Add-CodeEditor -Default -Name Atom -Path "$env:APPDATA\..\Local\atom\atom.exe"

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
        $Path,

        [Parameter()]
        [switch]
        $Default
    )

    $editors = Get-CodeEditor -ListAvailable
    $editors[$Name] = @{
        name = $Name
        path = $Path
    }
    Save-SecureStringToFile -Identifier git.codeeditors.all -Object $editors

    if ($Default) {
        $null = Switch-DefaultCodeEditor -Name $Name
    }

    return $editors
    
}