
<#
    .SYNOPSIS
    Creates a new Pull-Request from Dev to Master based on the Current Repository Location.

    .DESCRIPTION
    Creates a new Pull-Request from Dev to Master based on the Current Repository Location.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None.


    .EXAMPLE

    Create a new Pull-Request from Dev to Master in Azure DevOps in the current Repository:

    PS> New-MasterPR -PRTitle '<Title>'

    .LINK
        
#>
function New-MasterPR {

    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $PRtitle,

        # Switch to skip opening in the browser
        [switch]
        $noBrowser
    )

    New-PullRequest -Source 'dev' -Target 'default' -autocompletion -PRtitle $PRTitle -noBrowser:$noBrowser
}