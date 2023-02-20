
<#
    .SYNOPSIS
    Creates a new Branch in the Current Repository, based on a workitem assigned to the current user.

    .DESCRIPTION
    Creates a new Branch in the Current Repository, based on a workitem assigned to the current user.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Create a new Branch in the current repository from a workitem:

    PS> New-BranchFromWorkitem '<item_from_autocomplete>'


    .LINK
        
#>

function New-BranchFromWorkitem {

    [Alias('gitW')]
    param (
        # Autocomplete list for workitems assigned to the user.
        [Parameter(Mandatory = $true)]
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
        $workitemTitle
    )    

    git rev-parse >nul 2>&1; 
    if (!$?) {
        throw 'Please exexcute command inside a Repository'
    }

    $workItem = Search-WorkItemInIteration -Current -Personal -Single -SearchTags $workitemTitle
    $transformedTitle = $workItem.fields.'System.Title'.toLower() -replace '[?!:\/\\\-\s]+', '_' -replace '[\[\]]+', '__'
    $branchName = "features/$($workItem.id)-$transformedTitle"
        
    git checkout master
    git pull origin master
    git checkout dev
    git pull origin dev
    git checkout -b "$branchName"

}