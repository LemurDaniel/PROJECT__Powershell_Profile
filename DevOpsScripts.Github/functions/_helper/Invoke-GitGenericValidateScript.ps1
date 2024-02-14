function Invoke-GitGenericValidateScript {
    param(
        # The value to validate.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Value,

        # The hashtable of bound powrshell parameters.
        [Parameter(
            Mandatory = $true
        )]
        [System.Collections.Hashtable]
        $BoundParameters,

        # The name of the parameter to validate.
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $ParameterName
    )

    if ([System.String]::IsNullOrEmpty($Value)) {
        return $true
    }


    $validValues = Get-GitParameterValidValues -ParameterName $ParameterName -BoundParameters $BoundParameters

    if ($Value -IN $validValues) {
        return $true
    }

    Write-Error "`n`n*** '$Value' is not a valid value for '$ParameterName'! ***`n`n"
}