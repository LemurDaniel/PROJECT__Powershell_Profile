<#
    .SYNOPSIS
    Switches the current Organization Context.

    .DESCRIPTION
    Switches the current Organization Context based on the User connected via Connect-AzAccount.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Set the current Organization-Context by name.

    PS> Switch-Organization <Organization_name>


    .LINK
        
#>
function Switch-Organization {

    [Alias('Set-OrgContext', 'swo')]
    [CmdletBinding()]
    param (
        # The name of the Organization to switch to.
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
                param($cmd, $param, $wordToComplete)
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