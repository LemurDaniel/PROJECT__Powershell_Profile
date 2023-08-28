

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
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-CodeEditor -ListAvailable).Keys
            }
        )]
        [System.String]
        $Programm,

        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $Path
    )

    $Process = @{
        WindowStyle  = ( Get-CodeEditor -Programm $Programm).windowStyle
        FilePath     = (Get-CodeEditor -Programm $Programm).path
        ArgumentList = '"' + $path + '"' # Needs to be in dobule quotes for paths with spaces
    }

    Start-Process @Process 
    
}