
<#
    .SYNOPSIS
    Start a Pipeline by id on a specific branch. Use Start-Pipeline instead.

    .DESCRIPTION
    Start a Pipeline by id on a specific branch. Use Start-Pipeline instead.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .LINK
        
#>
function Start-PipelineOnBranch {
    param (
        [Parameter()]
        [System.int32]
        $id,

        [Parameter()]
        [System.String]
        $ref
    )
  
    # Run Pipeline.
    $Request = @{
        Method      = 'POST'
        Domain      = 'dev.azure'
        SCOPE       = 'PROJ'
        API         = '/_apis/build/builds?api-version=6.0'
        Body        = @{
            definition   = @{ id = $id }
            sourceBranch = $ref
        }
    }
    return Invoke-DevOpsRest @Request

}