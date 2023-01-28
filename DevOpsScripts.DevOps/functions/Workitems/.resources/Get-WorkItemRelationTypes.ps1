
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
function Get-WorkItemRelationTypes {

    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = 'specific'
        )]
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

        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'all'
        )]
        [switch]
        $All,


        # The Property to return from the items. If null will return full Properties.
        [Alias('return')]
        [Parameter()]
        [System.String]
        $Property
    )

    $workItemRelationTypes = ((Get-Content "$PSScriptRoot\WorkItemRelationTypes.json") | ConvertFrom-Json).value
    if (!$All) {
        $workItemRelationTypes = $workItemRelationTypes | Where-Object -Property name -EQ -Value $RelationType 
    } 
    
    return Get-Property -Object $workItemRelationTypes -Property $Property
}