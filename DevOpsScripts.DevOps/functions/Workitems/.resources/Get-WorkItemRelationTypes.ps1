
<#
    .SYNOPSIS
    Gets Information about a DevOps WorkItemRelationTypes.

    .DESCRIPTION
    Gets Information about a DevOps WorkItemRelationTypes.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Download an open a repository in the current DevOps-Context:

    PS> Get-WorkItemRelationType '<repository_name>'


    .LINK
        
#>
function Get-WorkItemRelationType {

    [CmdletBinding()]
    param (

        [Parameter()]
        [ValidateScript(
            {
                $_ -in ((Get-Content "$PSScriptRoot\WorkItemRelationTypes.json") | ConvertFrom-Json).value.name
            }
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = ((Get-Content "$PSScriptRoot\WorkItemRelationTypes.json") | ConvertFrom-Json).value.name
     
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $RelationType,


        # The Property to return from the items. If null will return full Properties.
        [Alias('return')]
        [Parameter()]
        [System.String]
        $Property
    )

    $workItemRelationType = ((Get-Content "$PSScriptRoot\WorkItemRelationTypes.json") | ConvertFrom-Json).value | Where-Object -Property name -EQ -Value $RelationType
    return Get-Property -Object $workItemRelationType -Property $Property
}