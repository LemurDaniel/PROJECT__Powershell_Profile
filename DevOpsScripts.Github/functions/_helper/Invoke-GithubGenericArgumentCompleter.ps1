function Invoke-GithubGenericArgumentCompleter {
    param ( 
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

        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $alias
    )

    $parameterName = [System.String]::IsNullOrEmpty($alias) ? $parameterName : $alias
    $validValues = Get-GithubParameterValidValues -ParameterName $parameterName -BoundParameters $fakeBoundParameters


    if ($null -EQ $validValues -OR $validValues.Count -EQ 0) {
        return "'<no values...>'"
    }

    return $validValues 
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