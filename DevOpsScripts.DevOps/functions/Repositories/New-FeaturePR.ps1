
<#
    .SYNOPSIS
    Creates a new Pull-Request from Feature to Dev based on the Current Repository Location.

    .DESCRIPTION
    Creates a new Pull-Request from Feature to Dev based on the Current Repository Location.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None.

    .LINK
        
#>
function New-FeaturePR {

    param(
        # Enable autcompletion of PR.
        [Parameter()]
        [switch]
        $autocompletion
    )

    New-PullRequest -Target 'dev' -autocompletion:$autocompletion -deleteSourceBranch
}