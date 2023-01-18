function Get-RepositoryRefs {

    [CmdletBinding()]
    param ( 
        [Parameter(Mandatory = $false)]
        [System.String]
        $path,

        [Parameter(Mandatory = $false)]
        [System.String]
        $id
    )  

    $repositoryId = Get-RepositoryInfo -Property 'id' -path $path -id $id
    
    $Request = @{
        METHOD   = 'GET'
        SCOPE    = 'PROJ'
        API      = "/_apis/git/repositories/$($repositoryId)/refs"
        Property = 'value'
    }
    
    return Invoke-DevOpsRest @Request 
}
