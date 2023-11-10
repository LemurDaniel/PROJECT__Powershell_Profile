

<#
    .SYNOPSIS
    Converts an HSV-Color to an RGB-Color.
    (NOTE: RGB to HSV is alread supported by .NET [Systen.Drawing.Color], but not the other way around)

    .DESCRIPTION
    Converts an HSV-Color to an RGB-Color.
    (NOTE: RGB to HSV is alread supported by .NET [Systen.Drawing.Color], but not the other way around)

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS

    .EXAMPLE

    Convert a hue of 120° with full saturation and brightness

    PS> $rgb = ConvertTo-RGB -Hue 120 -Saturation 1 -Value 1 # This should become Green

    .EXAMPLE

    Many more validated Examples:

    PS> ConvertTo-RGB -Hue  30 -Saturation   1 -Value   1  # Should be (FF)FF8000
    PS> ConvertTo-RGB -Hue 360 -Saturation   1 -Value   1  # Should be (FF)FF0000
    PS> ConvertTo-RGB -Hue   0 -Saturation   1 -Value   1  # Should be (FF)FF0000
    PS> ConvertTo-RGB -Hue 120 -Saturation 0.5 -Value 0.1  # Should be (FF)0C190C
    PS> ConvertTo-RGB -Hue  30 -Saturation 0.3 -Value 0.3  # Should be (FF)4C4135

    # These Examples were tested with this online converter: https://www.peko-step.com/de/tool/hsvrgb.html
    # NOTE
    #   - The SV values from this function range in (0.0 - 1.0)
    #   - The online converter ranges from (0 - 100)
    # So 0.5 is 50, 0.3 is 30 and so on in the online converter

    .LINKS

    ChatGPT + Wikipedia Algorithm: https://de.wikipedia.org/wiki/HSV-Farbraum#Umrechnung_HSV_in_RGB

#>


function ConvertTo-RGB {

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true
        )]
        [System.Single]
        [ValidateRange(0, 360)] 
        $Hue,

        [Parameter(
            Mandatory = $true
        )]
        [System.Single]
        [ValidateRange(0, 1)]
        $Saturation,

        [Parameter(
            Mandatory = $true
        )]
        [System.Single]
        [ValidateRange(0, 1)]
        $Value,

        # Transparency
        [Parameter(
            Mandatory = $false
        )]
        [System.Byte]
        $Alpha = 255
    )

    $Red = $null
    $Blue = $null
    $Green = $null

    if ($Saturation -LT [System.Math]::Pow(10, -5)) {
        $Red = $Value
        $Blue = $Red
        $Green = $Blue
    } 
    else {
        $h = [System.Math]::Floor($hue / 60)
        $f = ($hue / 60) - $h
        $p = $Value * (1 - $Saturation)
        $q = $Value * (1 - $Saturation * $f)
        $t = $Value * (1 - $Saturation * (1 - $f))

        Switch ($h) {

            { $_ -in @(0, 6) } {
                $Red = $Value
                $Green = $t
                $Blue = $p
                break
            }

            1 {
                $Red = $q
                $Green = $Value
                $Blue = $p
                break
            }

            2 {
                $Red = $p
                $Green = $Value
                $Blue = $t
                break
            }

            3 {
                $Red = $p
                $Green = $q
                $Blue = $Value
                break
            }

            4 {
                $Red = $t
                $Green = $p
                $Blue = $Value
                break
            }

            5 {
                $Red = $Value
                $Green = $p
                $Blue = $q
                break
            }

            default {
                throw [System.InvalidOperationException]::new("Something went wrong")
            }
        }
    }

    return [System.Drawing.Color]::fromArgb($Alpha,
        [System.Math]::Floor($Red * 255),
        [System.Math]::Floor($Green * 255),
        [System.Math]::Floor($Blue * 255)
    )

}