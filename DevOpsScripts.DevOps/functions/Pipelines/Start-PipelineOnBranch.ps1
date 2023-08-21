
<#
    .SYNOPSIS
    Start a Pipeline by id on a specific branch. Use Start-Pipeline instead.

    .DESCRIPTION
    Start a Pipeline by id on a specific branch. Use Start-Pipeline instead.
    Helper Method. Use Start-Pipeline instead.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .EXAMPLE

    Start a Pipeline id on a branch:

    PS> Start-PipelineOnBranch -Project <project> -id <pipeline_id> -ref "refs/heads/dev"

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
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-OrganizationInfo).projects.name
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