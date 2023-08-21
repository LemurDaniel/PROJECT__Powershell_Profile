
function Get-DevOpsOrganizationData {

    [cmdletbinding()]
    param(
        [Parameter(
            Mandatory = $false
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

    $Organization = [System.String]::IsNullOrEmpty($Organization) ? (Get-DevOpsContext -Organization) : $Organization
    return Get-DevOpsOrganizations | Where-Object { $_.accountName -EQ $Organization }

}