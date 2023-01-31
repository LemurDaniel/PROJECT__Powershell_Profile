<#
    .SYNOPSIS
    Gets Workitems in the current project by id.

    .DESCRIPTION
    Gets Workitems in the current project by id.

    .INPUTS
    You can Pipe ids into the command via other commands.

    .OUTPUTS
    System.PSCustomObject[] List of workitems from DevOps-API.

    The 'return' parameter specifies to return only a sub-attribute of the result.

    .EXAMPLE

    Get Workitmes by ids:

    PS> 1,2,3 | Get-Workitems

    .EXAMPLE

    Get Workitmes by previous search-query

    PS> Select-Workitems -Query 'query' | Get-Property 'workitems.id' | Get-Workitems


    .LINK
        
#>

function Get-WorkItem {

    [CmdletBinding(DefaultParameterSetName="expand")]
    param(
        # List of workitem ids to return
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [System.int32]
        $Id,

        # The Property to return from the items. If null will return full Properties.
        [Parameter(ParameterSetName="fields")]
        [System.String]
        $fields,

        [ValidateSet("None", "Relations", "Fields", "Links", "All")]
        [Parameter(ParameterSetName="expand")]
        [System.String]
        $expand

    )
    Begin {
    }
    Process {
        $Request = @{
            Method = 'GET'
            SCOPE  = 'PROJ'
            API    = '_apis/wit/workitems/' + $Id + '?api-version=7.0'
            Query  = @{}
        }
        if ($PSBoundParameters.ContainsKey("fields")) {
            $Request.Query.fields = $fields -join ','
        }
        if($PSBoundParameters.ContainsKey("expand")){
            $Request.Query.'$expand' = $expand
        }

        $response = Invoke-DevOpsRest @Request
    }
    End {
        return $response
    }   
}
