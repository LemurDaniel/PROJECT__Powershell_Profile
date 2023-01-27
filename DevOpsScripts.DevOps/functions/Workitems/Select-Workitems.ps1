
<#
    .SYNOPSIS
    Select Worktimes based on a wiql-Query in folder or DevOps accessbible by the user.

    .DESCRIPTION
    Select Worktimes based on a wiql-Query in folder or DevOps accessbible by the user.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    returns a list of queried workitems.


    .EXAMPLE

    Select-Workitems based on a defined query:

    PS> Select-Workitems '<item_from_autocomplete_list>'

    .EXAMPLE

    Select-Workitems based on a custom Query:

    PS> Select-Workitems '<custom_wiql_query_as_string>'

    .LINK
        
#>

function Select-Workitems {

    [CmdletBinding()]
    param(

        # Autocomplted list of Queries
        [Parameter(Mandatory = $true)]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $predefined = (Get-ChildItem -Path "$PSScriptRoot\predefinedQueries" -Filter '*.wiql').name -replace '.wiql', ''
                $validValues = @((Get-WorkItemQueries name), $predefined) 

                $validValues | `
                    ForEach-Object { $_ } | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Query,


        # The Property to return from the items. If null will return full Properties.
        [Alias('return')]
        [Parameter()]
        [System.String]
        $Property
    )

    if ($Query -in (Get-WorkItemQueries name)) {

        $id = Get-WorkItemQueries | Where-Object -Property name -EQ -Value $Query | Select-Object -ExpandProperty id
        $Request = @{
            Method = 'GET'
            SCOPE  = 'PROJ'
            API    = "_apis/wit/wiql/$id`?api-version=7.0"
        }
    }
    else {
        $QueryStatement = Get-Content -Raw -Path "$PSScriptRoot/predefinedQueries/$Query.wiql" -ErrorAction SilentlyContinue
        $QueryStatement = [System.String]::IsNullOrEmpty($QueryStatement) ? $Query : $QueryStatement
        $QueryStatement = $QueryStatement -replace '((\/+\*+){1}([^*]|[\n]|(\*+([^*\/]|[\n])))*(\*+\/+){1})', ''
        $QueryStatement = $QueryStatement -replace '\n', ' '
        $QueryStatement = $QueryStatement -replace '\s+', ' '
        #$QueryStatement = $QueryStatement -replace '{{PROJECT}}', (Get-ProjectInfo 'name')

        $Request = @{
            Method = 'POST'
            SCOPE  = 'PROJ'
            API    = '_apis/wit/wiql?api-version=5.1'
            Body   = @{
                query = $QueryStatement
            }
        }
    }

    return Invoke-DevOpsRest @Request -return $Property 
   
}
