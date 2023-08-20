
function Get-DevOpsOrganizationData {

    [cmdletbinding()]
    param(
        [Parameter(
            Mandatory = $true
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-DevOpsOrganizations).accountName
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Organization
    )

    return Get-DevOpsOrganizations | Where-Object { $_.accountName -EQ $Organization }

}