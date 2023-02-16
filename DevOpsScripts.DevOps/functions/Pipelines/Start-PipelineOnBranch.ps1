
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
        # The name of the Project to swtich to in which you want to open a repository. Will default to curren tproject context.
        [Parameter(
            Mandatory = $false
        )]   
        [ValidateScript(
            { 
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-DevOpsProjects).name
            },
            ErrorMessage = 'Please specify a correct Projectname.'
        )]
        [System.String]
        $Project,

        [Parameter(
            Mandatory = $true
        )]
        [System.int32]
        $id,

        [Parameter()]
        [System.String]
        $ref
    )
  
    # Run Pipeline.
    $Request = @{
        Method  = 'POST'
        Domain  = 'dev.azure'
        SCOPE   = 'PROJ'
        Project = $Project
        API     = '/_apis/build/builds?api-version=6.0'
        Body    = @{
            definition   = @{ id = $id }
            sourceBranch = $ref
        }
    }
    return Invoke-DevOpsRest @Request

}