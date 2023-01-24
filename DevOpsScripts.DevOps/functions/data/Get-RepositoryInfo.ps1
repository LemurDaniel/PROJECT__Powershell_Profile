function Get-RepositoryInfo {

    [CmdletBinding()]
    param ( 
        [Parameter(
            Mandatory = $false,
            Position = 0
        )]
        [ValidateScript(
            { 
                $_ -in (Get-ProjectInfo 'repositories.name')
            },
            ErrorMessage = 'Please specify an correct Name.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = Get-ProjectInfo 'repositories.name' 
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $path,


        [Parameter()]
        [System.String]
        $id,

        [Parameter()]
        [System.String]
        $Property,

        # Force API-Call and overwrite Cache
        [Parameter()]
        [switch]
        $refresh
    )  


    $repositories = Get-ProjectInfo 'repositories' -refresh:$refresh
    if (![System.String]::IsNullOrEmpty($Name)) {
        $repository = $repositories | Where-Object -Property Name -EQ -Value $Name
    }
    elseif (![System.String]::IsNullOrEmpty($id)) {
        $repository = $repositories | Where-Object -Property id -EQ -Value $id
    }
    else {
        # Get Current repository from VSCode Terminal, if nothing is specified.
        $path = [System.String]::IsNullOrEmpty($path) ? (git rev-parse --show-toplevel) : $path
        $repoName = $path.split('/')[-1]
        $repository = Search-In $repositories -where 'name' -is $repoName
    }

    if (!$repository) {
        Throw "Repository '$($repoName)' not found in current Project '$(Get-ProjectInfo 'name')'"
    }

    return Get-Property -Object $repository -Property $Property
}