
function Get-CodeEditor {

    param (
        [Parameter(
            Mandatory = $true,
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
    if ($null -EQ $editors) {
        Save-SecureStringToFile -Identifier git.codeeditors.all -Object (
            @{
                'Visual Studio Code' = @{
                    path = 'code'
                }
                'Visual Studio'      = @{
                    path = 'devenv'
                }
            }
        )
        $editors = Read-SecureStringFromFile -Identifier git.codeeditors.all -AsHashTable
    }

    if ($ListAvailable) {
        return $editors
    }
    else {
        return $editors[$Programm]
    }
    
}