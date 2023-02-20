<#
    .SYNOPSIS
    Opens a Workitem in the Browser.

    .DESCRIPTION
    Opens a Workitem in the Browser.

    .INPUTS
    None. You cannot pipe objects into New-Workitem

    .OUTPUTS
    None


    .EXAMPLE

    Open a Workitem by id in the Browser:

    PS> Open-WorkItemInBrowser -Id <id>


    .EXAMPLE

    Open some workitems in the Browser:

    PS> $workItems = Search-WorkItemInIteration -Current | Select-Object -First 3
    PS> $workItems.id | Open-WorkItemInBrowser

    .LINK
        
#>

function Open-WorkItemInBrowser {

    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param(
        # Id of the workitem
        [parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [System.Int32]
        $Id
    )

    BEGIN {}
    PROCESS {

        $workItem = Get-WorkItem -Id $Id
        $workItemUrl = $workItem.url -replace '/_apis/wit/workItems/', '/_workitems/edit/'
        Start-Process $workItemUrl

    }
    END {}
}