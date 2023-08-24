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

    PS> swo <autocompleted_Organization_name> <autocompleted_Project_name>


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
            ErrorMessage = 'Please specify an correct Organization Name.'
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
        $Name,

        # The name of the Project in the Organization to switch to.
        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
                
                $validValues = Get-OrganizationInfo -Organization $fakeBoundParameters['Name'] 
                | Select-Object -ExpandProperty projects
                | Select-Object -ExpandProperty name
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            { 
                $_ -in (
                    Get-OrganizationInfo -Organization $PSBoundParameters['Name'] 
                    | Select-Object -ExpandProperty projects
                    | Select-Object -ExpandProperty name
                )
            },
            ErrorMessage = 'Please specify an correct Organization Name.'
        )]
        [System.String]
        $Project
    )

    $matches = Get-OrganizationInfo -Organization $Name 
    | Select-Object -ExpandProperty projects
    | Where-Object -Property Name -eq $Project 
    | Measure-Object

    if ($matches.Count -eq 0) {
        Throw "'$Project' is not a valid Projectname in the Organization '$Name'"
    }   

    $null = Set-DevOpsContext -Organization $Name -Project $Project
    Show-DevOpsContext
}