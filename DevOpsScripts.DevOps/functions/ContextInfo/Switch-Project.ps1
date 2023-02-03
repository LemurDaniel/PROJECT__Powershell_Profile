<#
    .SYNOPSIS
    Switches the current Project Context.

    .DESCRIPTION
    Switches the current Organization Context based on the User connected via Connect-AzAccount and the Organization-Context.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Set the current Project-Context by name.

    PS> Switch-Project <autocompleted_Project_name>


    .LINK
        
#>

function Switch-Project {

    [Alias('Set-ProjectContext', 'swp')]
    [CmdletBinding()]
    param (
        # The name of the Project to swtich to.
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [ValidateScript(
            { 
                $_ -in (Get-DevOpsProjects).name
            },
            ErrorMessage = 'Please specify an correct Name.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-DevOpsProjects).name 
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Name
    )
     
    $null = Set-DevOpsContext -Project $Name
    Show-DevOpsContext
    
}