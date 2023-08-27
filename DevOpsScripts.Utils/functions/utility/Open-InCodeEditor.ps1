

<#
    .SYNOPSIS
    Opens a folder in a specified programm.

    .DESCRIPTION
    Opens a folder in a specified programm.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS

#>

function Open-InCodeEditor {

    param (
        [Parameter(
            Mandatory = $false
        )]
        [ArgumentCompleter(
            {
                return (Get-CodeEditor -ListAvailable).Keys
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ }
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-CodeEditor -ListAvailable).Keys
            }
        )]
        [System.String]
        $Programm = 'code',

        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $Path
    )

    Start-Process -FilePath (Get-CodeEditor -Programm $Programm).path -ArgumentList $Path
    
}