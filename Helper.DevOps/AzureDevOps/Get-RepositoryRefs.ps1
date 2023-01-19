function Get-RepositoryRefs {

    [CmdletBinding()]
    param ( 
        [Parameter(Mandatory = $false)]
        [System.String]
        $path,

        [Parameter(Mandatory = $false)]
        [System.String]
        $id,

        [Parameter(Mandatory = $false)]
        [Switch]
        $Tags
    )  

    $repositoryId = Get-RepositoryInfo -Property 'id' -path $path -id $id
    $Request = @{
        METHOD = 'GET'
        SCOPE  = 'PROJ'
        API    = "/_apis/git/repositories/$($repositoryId)/refs?api-version=7.0"
        return = 'value'
        query  = $Tags ? @{
            filter = 'tags'
        } : $null
    }

    return Invoke-DevOpsRest @Request 
}
