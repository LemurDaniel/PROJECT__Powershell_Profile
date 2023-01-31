function Open-BlenderFile {

    [CmdletBinding()]
    param (

        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = 'Profile'
        )]
        [ValidateScript(
            { 
                $_ -in (Get-BlenderFiles | get name)
            },
            ErrorMessage = 'Please specify the correct File.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = Get-BlenderFiles | get name
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $BlenderFile
    )

    $filePath = Get-BlenderFiles | Search -has $BlenderFile | get FullName
    Start-Process $filePath
}