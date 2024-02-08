

<#
    .SYNOPSIS
    Sets the default code editor for Open-InCodeEditor

    .DESCRIPTION
    Sets the default code editor for Open-InCodeEditor

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS

#>


function Switch-DefaultCodeEditor {

    param (
        [Parameter(
            Mandatory = $true
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                
                return (Get-CodeEditor -ListAvailable).Keys
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ }
            }
        )]
        [ValidateScript(
            {
                # needs to be case sensitive 
                $_ -cin (Get-CodeEditor -ListAvailable).Keys
            },
            ErrorMessage = "Please, enter a valid value."
        )]
        [System.String]
        $Name
    )

    return Set-UtilsConfiguration -Object $Name -Identifier git.codeeditor.current
    
}