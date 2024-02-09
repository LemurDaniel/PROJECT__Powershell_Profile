
function Invoke-AutoCompleterFileName {

    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $commandName,

        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $parameterName,

        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $wordToComplete,

        [Parameter(
            Mandatory = $true
        )]
        $commandAst,

        [Parameter(
            Mandatory = $true
        )]
        [System.Collections.Hashtable]
        $fakeBoundParameters,


        # The files to filter for. Like *.json, *.tf, etc.
        [Parameter(
            Mandatory = $false
        )]
        $Filter,

        # The hashtable of bound powrshell parameters.
        [Parameter(
            Mandatory = $true
        )]
        [ValidateRange(1, 8)]
        [System.Byte]
        $Depth = 3
    )

    $currentLocation = (Get-Location).Path
    return Get-ChildItem -Recurse -Filter $Filter -Depth $Depth
    | ForEach-Object {
        return $_.FullName.replace($currentLocation, '')
    }
    | Where-Object {
        if ($wordToComplete.Length -LT 3) {
            return $_.toLower() -like "$wordToComplete*".toLower() 
        }
        else {
            return $_.toLower() -like "*$wordToComplete*".toLower() 
        }
    } 
    | ForEach-Object { 
        $_ -match '\s' ? "'$_'" : $_
    }
    
}
