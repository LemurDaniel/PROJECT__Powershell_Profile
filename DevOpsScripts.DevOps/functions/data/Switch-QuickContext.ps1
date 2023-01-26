
function Switch-QuickContext {

    [Alias('swc')]
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [ValidateScript(
            { 
                $_ -in (Get-QuickContexts).Keys
            },
            ErrorMessage = 'Please specify the correct Context.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-QuickContexts).Keys
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $ContextName
    )

    $Organization = (Get-QuickContexts)[$ContextName].Organization
    $Project = (Get-QuickContexts)[$ContextName].Project
    $null = Set-DevOpsCurrentContext -Organization $Organization -Project $Project

    Show-DevOpsContext
}