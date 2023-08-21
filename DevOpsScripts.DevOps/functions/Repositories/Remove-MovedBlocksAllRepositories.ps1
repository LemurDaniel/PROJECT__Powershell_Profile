
<#
    .SYNOPSIS
    Remove all terraform moved blocks across all repositories.

    .DESCRIPTION
    Remove all terraform moved blocks across all repositories.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None.

    .EXAMPLE

    Filter and Remove terraform moved blocks in all repos of a project:

    PS> Remove-MovedBlocksAllRepositories -Project <project> -WorkitemTitle <autocomplete>

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
                $validValues = (Get-OrganizationInfo).projects.name
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Project
    )

    Invoke-ScriptInRepositories -Project $Project -workitemTitle $workitemTitle -ScriptBlock {
        param($Repository, $Project)
        Remove-MovedBlocks -Path $Repository.Localpath
    }

}

<#
Invoke-ScriptInRepositories -Project 'DC Azure Migration' -workitemTitle 'Fix outputs naming inconsistensies' -ScriptBlock { 
    param($Repository, $Project)  
    Edit-RegexOnFiles -Confirm:$false -replacementPath $Repository.Localpath -regexQuery 'acf_owners_id' -replace 'acf_launchpad_owner_ids'
}
#>