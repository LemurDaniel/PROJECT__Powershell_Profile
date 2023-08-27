
function Get-CodeEditor {

    [CmdletBinding(
        DefaultParameterSetName = 'Specific'
    )]
    param (
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'Specific'
        )]
        [System.String]
        $Programm,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'ListAvailable'
        )]
        [switch]
        $ListAvailable
    )

    $editors = Read-SecureStringFromFile -Identifier git.codeeditors.all -AsHashTable
    if ($null -EQ $editors -OR $editors.count -EQ 0) {
        Save-SecureStringToFile -Identifier git.codeeditors.all -Object (
            @{
                'Visual Studio Code' = @{
                    name = 'Visual Studio Code'
                    path = 'code'
                }
                'Visual Studio'      = @{
                    name = 'Visual Studio'
                    path = 'devenv'
                }
            }
        )
        $editors = Read-SecureStringFromFile -Identifier git.codeeditors.all -AsHashTable
    }

    if ($ListAvailable) {
        return $editors
    }


    if ([System.String]::IsNullOrEmpty($Programm)) {
        $Programm = Get-UtilsCache -Identifier git.codeeditor.current 
    }

    if ([System.String]::IsNullOrEmpty($Programm)) {
        $Programm = Switch-DefaultCodeEditor -Name $editors.Keys[0]
    }

    return $editors[$Programm]
    
}