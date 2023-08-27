function Open-BlenderFile {

    [CmdletBinding()]
    param (

        #[Parameter(
        #    Position = 0,
        #    Mandatory = $false,
        #    ParameterSetName = 'Profile'
        #)]
        #[ValidateScript(
        #    { 
        #        $_ -in (Get-BlenderFiles | get name)
        #    },
        #    ErrorMessage = 'Please specify the correct File.'
        #)]
        #[ArgumentCompleter(
        #    {
        #        param($cmd, $param, $wordToComplete)
        #        $validValues = Get-BlenderFiles | get name
        #        
        #        $validValues | `
        #            Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
        #            ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
        #    }
        #)]
        #[System.String]
        #$BlenderFile
    )

    $BlenderFile = Select-ConsoleMenu -Property display -Options (Get-BlenderFiles 
        | ForEach-Object {
            return @{
                display = "$($_.Directory.name)/$($_.name)"
                path    = $_.FullName
            }
        })

    if ($null -NE $BlenderFile) {
        Start-Process -FilePath $BlenderFile.path
    }
}