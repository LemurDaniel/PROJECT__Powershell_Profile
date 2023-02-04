
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
                $_ -in (Get-WorkItemRelationTypes -All).name
            }
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = Get-WorkItemRelationTypes -All | Select-Object -ExpandProperty name
     
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
        $All
    )


    $workItemRelationTypes = Get-UtilsCache -Type WorkItemRelationTypes -Identifier all
        
    if(!$workItemRelationTypes){
        $Request = @{
            Method = 'GET'
            CALL   = 'ORG'
            API    = '_apis/wit/workitemrelationtypes?api-version=7.1-preview'
        }
        $workItemRelationTypes = Invoke-DevOpsRest @Request | Select-Object -ExpandProperty value
        $workItemRelationTypes = Set-UtilsCache -Object $workItemRelationTypes -Type WorkItemRelationTypes -Identifier all
    }

    if (!$All) {
        return $workItemRelationTypes | Where-Object -Property name -EQ -Value $RelationType 
    } else {
        return $workItemRelationTypes
    }
    
}