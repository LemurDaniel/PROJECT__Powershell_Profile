

<#
    .SYNOPSIS
    Creates an ANSI-Escape Sequences for customizing Terminal-Output.

    .DESCRIPTION
    Creates an ANSI-Escape Sequences for customizing Terminal-Output.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS



    # Adding lots of examples here:


    .EXAMPLE

    Write a text as italic, bold:
    
    PS> New-ANSIEscapeCode -Text "Some Text" -Italic -Bold

    .EXAMPLE

    Write a text as italic, bold with a 24bit-background in yellow:
    
    PS> New-ANSIEscapeCode -Text "Some Text" -Italic -Bold -Background "#FFFF00"

    .EXAMPLE

    Write a text as italic, bold with a 24bit-background in yellow:
    
    PS> New-ANSIEscapeCode -Text "Some Text" -Italic -Bold -Background "#FFFF00"

    .EXAMPLE

    Write a text as italic, bold with a 24bit-forground in yellow:
    
    PS> New-ANSIEscapeCode -Text "Some Text" -Italic -Bold -Foreground "#FFFF00"

    .EXAMPLE

    Write a text with an 8-bit color:

    PS> New-ANSIEscapeCode -Text "Some Text" -Foreground 27 -Colormode 8bit



    .EXAMPLE

    Get only the ANSICodes:
    
    PS> $ANSI = New-ANSIEscapeCode -Underline -Bold -Italic -Strikethrough -Blinking
    PS> Write-Host "$ANSI Some Text"
#>



function New-ANSIEscapeCode {

    param(
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Text,

        [Parameter()]
        [System.String]
        [ValidateSet("24bit", "8bit")]
        $Colormode = "24bit",

        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Background,

        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Foreground,


        [Parameter()]
        [switch]
        $Italic,

        [Parameter()]
        [switch]
        $Bold,

        [Parameter()]
        [switch]
        $Underline,

        [Parameter()]
        [switch]
        $Blinking,

        [Parameter()]
        [switch]
        $Inverse,

        [Parameter()]
        [switch]
        $Hidden,

        [Parameter()]
        [switch]
        $Strikethrough,

        [Parameter()]
        [switch]
        $NoReset
    )

    $ANSI = Get-ANSIEscapeSequences -AsObject
    $Formatted = @()

    if ($Colormode -EQ "24bit") {

        if ($PSBoundParameters.ContainsKey("Foreground")) {
       
            if ($Foreground -notmatch "^#[0-9A-F]{6}$") {
                throw [System.NotSupportedException]::new("'$Foreground' isn't a supported format. Please enter color as a hexcode.")
            }

            $Formatted += $ANSI.COLORS_24BIT.FOREGROUND `
                -replace "{R}", [System.Convert]::ToByte($Foreground.Substring(1, 2), 16) `
                -replace "{G}", [System.Convert]::ToByte($Foreground.Substring(3, 2), 16) `
                -replace "{B}", [System.Convert]::ToByte($Foreground.Substring(5, 2), 16)
        }

        if ($PSBoundParameters.ContainsKey("Background")) {
                
            if ($Background -notmatch "^#[0-9A-F]{6}$") {
                throw [System.NotSupportedException]::new("'$Background' isn't a supported format. Please enter color as a hexcode.")
            }

            $Formatted += $ANSI.COLORS_24BIT.BACKGROUND `
                -replace "{R}", [System.Convert]::ToByte($Background.Substring(1, 2), 16) `
                -replace "{G}", [System.Convert]::ToByte($Background.Substring(3, 2), 16) `
                -replace "{B}", [System.Convert]::ToByte($Background.Substring(5, 2), 16)
        }

    }

    elseif ($Colormode -EQ "8bit") {

        if ($PSBoundParameters.ContainsKey("Foreground")) {
       
            if ($Foreground -notmatch "\d") {
                throw [System.NotSupportedException]::new("'$Foreground' only a 8bit value between 0-255 is supported.")
            }

            $value = [System.Convert]::ToInt32($Foreground)
            if ($value -GT 255 -OR $value -LT 0) {
                throw [System.NotSupportedException]::new("'$Foreground' only a 8bit value between 0-255 is supported.")
            }

            $Formatted += $ANSI.COLORS_8BIT.FOREGROUND -replace "{ID}", $value
        }

        if ($PSBoundParameters.ContainsKey("Background")) {
                
            if ($Background -notmatch "\d") {
                throw [System.NotSupportedException]::new("'$Background' only a 8bit value between 0-255 is supported.")
            }

            $value = [System.Convert]::ToInt32($Background)
            if ($value -GT 255 -OR $value -LT 0) {
                throw [System.NotSupportedException]::new("'$Background' only a 8bit value between 0-255 is supported.")
            }

            $Formatted += $ANSI.COLORS_8BIT.BACKGROUND -replace "{ID}", $value
        }

    }

    if ($Bold) {
        $Formatted += $ANSI.graphics.BOLD.SET
    }
    if ($Italic) {
        $Formatted += $ANSI.graphics.ITALIC.SET
    }
    if ($Strikethrough) {
        $Formatted += $ANSI.graphics.STRIKETHROUGH.SET
    }
    if ($Hidden) {
        $Formatted += $ANSI.graphics.HIDDEN.SET
    }
    if ($Inverse) {
        $Formatted += $ANSI.graphics.INVERSE.SET
    }
    if ($Blinking) {
        $Formatted += $ANSI.graphics.BLINKING.SET
    }
    if ($Underline) {
        $Formatted += $ANSI.graphics.UNDERLINE.SET
    }

    if ($PSBoundParameters.ContainsKey("Foreground_8bit")) {
        $Formatted += $ANSI.COLORS_24BIT.BACKGROUND `
            -replace "{ID}", $Foreground_8bit
    }
    if ($PSBoundParameters.ContainsKey("Background_8bit")) {
        $Formatted += $ANSI.COLORS_8BIT.BACKGROUND `
            -replace "{ID}", $Background_8bit
    }

    $Formatted += $Text

    if ($PSBoundParameters.ContainsKey("Text") -AND !$NoReset) {
        $Formatted += $ANSI.graphics.RESET_ALL
    }

    <#
        if ($Bold -AND !$ResetAll) {
            $Formatted += $ANSI.graphics.BOLD.RESET
        }
        if ($Italic) {
            $Formatted += $ANSI.graphics.ITALIC.RESET
        }
        if ($Strikethrough) {
            $Formatted += $ANSI.graphics.STRIKETHROUGH.RESET
        }
        if ($Hidden) {
            $Formatted += $ANSI.graphics.HIDDEN.RESET
        }
        if ($Inverse) {
            $Formatted += $ANSI.graphics.INVERSE.RESET
        }
        if ($Blinking) {
            $Formatted += $ANSI.graphics.BLINKING.RESET
        }
        if ($Underline) {
            $Formatted += $ANSI.graphics.UNDERLINE.RESET
        }
    #>

    return $Formatted -join ''
}