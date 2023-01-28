
<#
    .SYNOPSIS
    Gets all references of a repository or of the current repository location.

    .DESCRIPTION
    Gets all refs of a repository or of the current repository location.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    return a list of all repository refs.


    .EXAMPLE

    Gets all refs for the current repository path.

    PS> Get-RepositoryRefs

    .EXAMPLE

    Gets all refs for a  Repository.

    PS> $id = Get-RepositoryInfo '<name>' -return id
    PS> Get-RepositoryRefs -id $id


    .LINK
        
#>

function Get-RepositoryRefs {

    [CmdletBinding()]
    param ( 
        # Optional path of the repository. (Needs to be a path from Get-RepositoryInfo 'Localpath')
        [Parameter(Mandatory = $false)]
        [System.String]
        $path,

        # Optional id of the repository. (Needs to be an id of Get-RepositoryInfo 'id')
        [Parameter(Mandatory = $false)]
        [System.String]
        $id,

        # Optional switch to only return tags.
        [Parameter(Mandatory = $false)]
        [Switch]
        $Tags,

        # Optional switch to only return heads.
        [Parameter(Mandatory = $false)]
        [Switch]
        $Heads,


        # Optional switch to include statuses
        [Parameter(Mandatory = $false)]
        [Switch]
        $Statuses
    )  

    $repositoryId = Get-RepositoryInfo -Property 'id' -path $path -id $id
    $filter = $Tags ? 'tags' : $Heads ? 'heads': $null
    $Request = @{
        METHOD = 'GET'
        SCOPE  = 'PROJ'
        API    = "/_apis/git/repositories/$($repositoryId)/refs?api-version=7.0"
        return = 'value'
        query  = @{
            includeStatuses = $Statuses
            filter          = $filter 
        } 
    }

    return Invoke-DevOpsRest @Request 
}
