function Get-RepositoryInfo {

    [CmdletBinding()]
    param ( 
        [Parameter(Mandatory = $false)]
        [System.String]
        $Property,

        [Parameter(Mandatory = $false)]
        [System.String]
        $path,

        [Parameter(Mandatory = $false)]
        [System.String]
        $id
    )  

    if ([System.String]::IsNullOrEmpty($id)) {
        $path = [System.String]::IsNullOrEmpty($path) ? (git rev-parse --show-toplevel) : $path
        $repoName = $path.split('/')[-1]
        $repositories = Get-ProjectInfo 'repositories'
        $repository = Search-In $repositories -where 'name' -is $repoName
    }
    else {
        $repository = Get-ProjectInfo 'repositories' | Where-Object -Property id -EQ -Value $id
    }

    return Get-Property -Object $repository -Property $Property
}