
<#
    .SYNOPSIS
    Draws an Git emojie returned by the api onto the console.

    .DESCRIPTION
    Draws an Git emojie returned by the api onto the console.

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
function Show-GitEmojie {

    [Alias('git-emojie')]
    param(
        
        # An emojie returned from the Git api.
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                return (Get-GitEmojies).Keys
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ }
            }
        )]
        $Emojie,

        [Parameter(
            Mandatory = $false
        )]
        $Height,

        [Parameter(
            Mandatory = $false
        )]
        $Width,

        # Ignore alpha channel.
        [Parameter()]
        [switch]
        $NoAlpha,
        
        # Set with to maximum.
        [Parameter()]
        [switch]
        $Stretch,
        
        # Center image in console.
        [Parameter()]
        [switch]
        $Center,
        
        # Prints image as grayscale/black&white/monochrome grey or whatever to call it.
        [Parameter()]
        [switch]
        $Grayscale
    )


    $Identifier = "gitub.emojies.$Emojie"
    $base64 = Get-UtilsCache -Identifier $Identifier

    if ($null -EQ $base64 -OR $Refresh) {
        $tempFile = [System.IO.Path]::GetTempFileName()
        Invoke-WebRequest -Uri (Get-GitEmojies)["$Emojie"] -OutFile $tempFile
        $base64 = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($tempFile))
        $base64 = Set-UtilsCache -Object $base64 -Identifier $Identifier -Forever
        Remove-Item -Path $tempFile -ErrorAction SilentlyContinue
    }

    $Parameters = @{
        Grayscale = $Grayscale
        Center    = $Center
        Stretch   = $Stretch
        NoAlpha   = $NoAlpha
        Width     = $Width
        Height    = $Height
        Base64    = $base64
    }
    Show-ConsoleImage @Parameters

}