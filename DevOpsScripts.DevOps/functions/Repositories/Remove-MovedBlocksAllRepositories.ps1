
<#
    .SYNOPSIS

    .DESCRIPTION

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None.


    .LINK
        
#>

function Remove-MovedBlocksAllRepositories {

    [cmdletbinding(
        SupportsShouldProcess,
        ConfirmImpact = 'high'
    )]
    param (
        # Autocomplete list for workitems assigned to the user.
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = Search-WorkItemInIteration -SearchTags '*' -Current -Personal -return 'fields.System.Title'  

                $validValues | `
                    ForEach-Object { $_ } | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $workitemTitle,


        # The name of the project, if not set default to the Current-Project-Context.
        [Parameter(
            ParameterSetName = 'projectSpecific',
            Mandatory = $false,
            Position = 1
        )]
        [ValidateScript(
            { 
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-DevOpsProjects).name
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
        $Project
    )

    Invoke-ScriptInAllRepositories -Project $Project -workitemTitle $workitemTitle -ScriptBlock {
        param($Repository, $Project)
        Remove-MovedBlocks -Path $Repository.Localpath
    }

}
