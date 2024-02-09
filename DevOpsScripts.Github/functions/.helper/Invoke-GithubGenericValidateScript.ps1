function Invoke-GithubGenericValidateScript {
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

    $validValues = Get-GithubParameterValidValues -ParameterName $ParameterName -BoundParameters $BoundParameters

    $isValid = [System.String]::IsNullOrEmpty($Value) -OR $Value -IN $validValues

    if (!$isValid) {
        Write-Error "`n`n*** '$Value' is not a valid value for '$ParameterName'! ***`n`n"
    }

    return $true
}