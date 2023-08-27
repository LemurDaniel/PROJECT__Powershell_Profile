

<#
    .SYNOPSIS
    Clear a code editor for opening with gitvc, etc.

    .DESCRIPTION
    Clear a editor for opening with gitvc, etc.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS

#>

function Clear-CodeEditor {

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

    $editors = Read-SecureStringFromFile -Identifier git.codeeditors.all -AsHashTable
    $editors.Remove($Name)
    Save-SecureStringToFile -Identifier git.codeeditors.all -Object $editors

    return $editors
    
}