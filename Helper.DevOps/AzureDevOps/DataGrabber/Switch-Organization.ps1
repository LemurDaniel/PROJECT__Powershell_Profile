
function Switch-Organization {

    [Alias('Set-OrgContext', 'swo')]
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [ValidateScript(
            { 
                $_ -in (Get-DevOpsOrganizations).accountName
            },
            ErrorMessage = 'Please specify an correct Name.'
        )]
        [ArgumentCompleter(
            {
                $validValues = (Get-DevOpsOrganizations).accountName
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Name
    )

    $null = Set-DevOpsCurrentContext -Organization $Name
    Write-Host -ForegroundColor GREEN "`n   Set Organization Context to '$Name'`n"
    
}