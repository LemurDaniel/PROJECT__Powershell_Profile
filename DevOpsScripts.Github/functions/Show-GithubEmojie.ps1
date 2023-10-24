
<#
    .SYNOPSIS
    Draws an github emojie returned by the api onto the console.

    .DESCRIPTION
    Draws an github emojie returned by the api onto the console.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS

    
    .EXAMPLE 

    Draw the alien emojie on the console:

    PS> git-emojie alien

    .EXAMPLE 

    Draw the dog emojie with a custom size:

    PS> git-emojie dog -Height 40 -Width 40


    
    .LINK
        
#>
function Show-GithubEmojie {

    [Alias('git-emojie')]
    param(
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                return (Get-GithubEmojies).Keys
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ }
            }
        )]
        $Emojie,

        [Parameter(
            Mandatory = $false
        )]
        $Height = 20,

        [Parameter(
            Mandatory = $false
        )]
        $Width = 20
    )


    $Identifier = "gitub.emojies.$Emojie"
    $base64 = Get-UtilsCache -Identifier $Identifier

    if ($null -EQ $base64 -OR $Refresh) {
        $tempFile = [System.IO.Path]::GetTempFileName()
        Invoke-WebRequest -Uri (Get-GithubEmojies)["$Emojie"] -OutFile $tempFile
        $base64 = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($tempFile))
        $base64 = Set-UtilsCache -Object $base64 -Identifier $Identifier -Forever
        Remove-Item -Path $tempFile -ErrorAction SilentlyContinue
    }

    Show-ConsoleImage -Width $Width -Height $Height -Base64 $base64

}