
<#
    .SYNOPSIS
    Attempts to draw an image onto the Terminal-Console.
    Use 'Strg' + '-' to make font smaller and get better quality. 

    .DESCRIPTION
    Attempts to draw an image onto the Terminal-Console.
    Use 'Strg' + '-' to make font smaller and get better quality. 

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS



    .EXAMPLE

    Draw a base64 encoded testimage to the center of the console

    PS> Show-ConsoleImage -Testimage <autocompleted_name>

    .EXAMPLE

    Draw a base64 encoded testimage to the console, covering the whole width, but preserving ratio:

    PS> Show-ConsoleImage -Center -Stretch -Testimage <autocompleted_name>

    .EXAMPLE

    Draw a base64 encoded testimage to the console without the alpha channel:

    PS> Show-ConsoleImage -Center -NoAlpha -Testimage <autocompleted_name>

    .EXAMPLE

    Draw the pixelmonster with a custom emojie:

    PS> Show-ConsoleImage -Center -Testimage pixelmonster -Pixel "👾"

    .EXAMPLE
    
    Draw a dog with a custom pixel in grayscale:

    PS> Show-ConsoleImage -Center -Grayscale -Testimage cutedog -Pixel "#"

    .EXAMPLE

    Draw a dog with a custom witdh, preserving ratio:

    PS> Show-ConsoleImage -Center -Testimage cutedog -Width 40 -Pixel "#"

    .EXAMPLE

    Draw a dog with random pixels:

    PS> Show-ConsoleImage -Center -Random -Testimage cutedog

    .EXAMPLE

    Some interesting looking character options:

    PS> Show-ConsoleImage -Center -Testimage cutedog -Pixel '*' -Background Black
    PS> Show-ConsoleImage -Center -Testimage cutedog -Pixel '@' -Background Black
    PS> Show-ConsoleImage -Center -Testimage cutedog -Pixel '^' -Background Black
    PS> Show-ConsoleImage -Center -Testimage cutedog -Pixel '°' -Background Black
    PS> Show-ConsoleImage -Center -Testimage cutedog -Pixel '~' -Background Black
    PS> Show-ConsoleImage -Center -Testimage cutedog -Pixel '+' -Background Black
    PS> Show-ConsoleImage -Center -Testimage cutedog -Pixel '&' -Background Black
    PS> Show-ConsoleImage -Center -Testimage cutedog -Pixel "'" -Background Black
    PS> Show-ConsoleImage -Center -Testimage cutedog -Pixel '"' -Background Black
    PS> Show-ConsoleImage -Center -Testimage cutedog -Pixel '_' -Background Black
    PS> Show-ConsoleImage -Center -Testimage cutedog -Pixel "><" -Background Black
    PS> Show-ConsoleImage -Center -Testimage cutedog -Pixel "{}" -Background Black
    PS> Show-ConsoleImage -Center -Testimage cutedog -Pixel "\/" -Background Black


    
    # Even more examples:

    .EXAMPLE

    Draw a honey flask in monochrome grey:

    PS> Show-ConsoleImage -Center -Stretch -Random -Grayscale -Testimage honey

    .EXAMPLE

    Draw a some fireworks:

    PS> Show-ConsoleImage -Center -Stretch -Pixel '#' -Testimage fireworks




    .EXAMPLE

    Draw an image saved in the clipboard:

    PS> Show-ConsoleImage -Stretch -Center -Clipboard

    .EXAMPLE

    Draw an image saved in the clipboard as grayscale:

    PS> Show-ConsoleImage -Stretch -Center -Grayscale -Clipboard



    .EXAMPLE

    Draw a file as an image to the console:

    PS> Show-ConsoleImage -Stretch -Center -File <autocompleted_path>



    # More stuff and Examples

    .EXAMPLE

    Some interesting black and white effects:

    PS> Show-ConsoleImage -Center -Testimage cutedog -BlackWhite 40 -Pixel '#'
    
    .EXAMPLE

    Some interesting black and white effects:

    PS> Show-ConsoleImage -Center -Testimage cutedog -BlackWhite 40 -Random

    .EXAMPLE

    Get some interesting monochrome effects:

    PS> Show-ConsoleImage -Center -Testimage cutedog -MonochromeColor Yellow -Saturation .5 -Brightness 1

    .EXAMPLE

    Make an image brigther:

    PS> Show-ConsoleImage -Center -Testimage cutedog -Brightness 2
    
    .EXAMPLE

    Make an image less bright and saturated:

    PS> Show-ConsoleImage -Center -Testimage cutedog -Brightness .8 -Saturation .5

    .EXAMPLE

    Get some more monochrome effects:

    PS> Show-ConsoleImage -Center -Testimage cutedog -MonochromeHue 270

    .EXAMPLE

    Get some more monochrome effects:

    PS> Show-ConsoleImage -Center -Testimage cutedog -MonochromeHue 120

    .EXAMPLE

    Get a grayscale effect by desaturation:

    PS> Show-ConsoleImage -Center -Testimage cutedog -Saturation 0



    .EXAMPLE

    Create a Sepia-like effect (Not Perfect though):

    PS> show-ConsoleImage -Center -Testimage cutedog2 -Preset Sepia

    .LINK
        
#>

function Show-ConsoleImage {

    [Alias(
        "print-img"
    )]
    [CmdletBinding(
        DefaultParameterSetName = "file"
    )]
    param(
        # Select an image from the testimage json
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = "testimage"
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
            
                return (Get-ConsoleTestImages).Keys                
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ }
            }
        )]
        [System.String]
        $Testimage,

        # Select an image file to draw the image from.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = "file"
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
    
                return Get-ChildItem -Depth 3 -Recurse -Include *.png, *.jpg, *.jpeg, *.bmp
                | Where-Object { 
                    $_.Name.toLower() -like "*$wordToComplete*".toLower() 
                } 
                | ForEach-Object {
                    $_.FullName.Replace((Get-Location).Path, "")
                }
                | ForEach-Object { 
                    $_.contains(' ') ? "'$_'" : $_ 
                } 
            }
        )]
        [System.String]
        $File,

        # Provide an image to draw.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = "image"
        )]
        [System.Drawing.Image]
        $Image,

        # Provide a base64 encoded image.
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = "base64"
        )]
        [System.String]
        $Base64,

        # Draw an image from the clipboard.
        [Parameter(
            Position = 0,
            ParameterSetName = "clipboard"
        )]
        [switch]
        $Clipboard,

        # Set the height of the image.
        [Parameter(
            Mandatory = $false
        )]
        [System.int32]
        $Height = -1,

        # Set the width of the image.
        [Parameter(
            Mandatory = $false
        )]
        [System.int32]
        $Width = -1,



        # When drawing colored characters in foreground, set a custom background for more contrast.
        [Parameter(
            Mandatory = $false
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
    
                return [System.Management.Automation.PSStyle]::Instance.Background.PSObject.Properties.name
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ }
            }
        )]
        [ValidateScript(
            {
                $_ -in [System.Management.Automation.PSStyle]::Instance.Background.PSObject.Properties.name
            },
            ErrorMessage = {
                "'$_' is not valid!"
            }
        )]
        [System.String]
        $Background,
        

        # Get some interesting monochrome results.
        # Select a predefined color.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        [ValidateSet("Red", "Orange", "Yellow", "Green", "Cyan", "Violett", "Blue", "Magenta")]
        $MonochromeColor,
        # Get some interesting monochrome results.
        # Select a hue by angle from the color wheel.
        [Parameter(
            Mandatory = $false
        )]
        [System.Int32]
        [ValidateRange(0, 360)]
        $MonochromeHue,


        # Change the saturation of the image.
        [Parameter(
            Mandatory = $false
        )]
        [System.Single]
        [ValidateRange(0, 10)]
        $Saturation,

        # Change the brightness of the image.
        [Parameter(
            Mandatory = $false
        )]
        [System.Single]
        [ValidateRange(0, 10)]
        $Brightness,


        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Pixel = " ",

        # Print each line with a delay, because looks funny.
        [Parameter(
            Mandatory = $false
        )]
        [System.int32]
        $Delay = 0,

        # Set alpha treshold
        [Parameter(
            Mandatory = $false
        )]
        [System.Byte]
        $AlphaTrs = 32,
        # Ignore alpha channel.
        [Parameter()]
        [switch]
        $NoAlpha,


        [Parameter()]
        [System.String]
        [ValidateSet('Sepia')]
        $Preset,

        # Set with to maximum.
        [Parameter()]
        [switch]
        $Stretch,

        # Center image in console.
        [Parameter()]
        [switch]
        $Center,

        # Prints image as grayscale/monochrome grey or whatever to call it.
        [Parameter()]
        [switch]
        $Grayscale,

        # Prints the picture in black and white
        [Parameter()]
        [System.Byte]
        $BlackWhite = 40,

        # Draw image with random characters.
        [Parameter()]
        [switch]
        $Random
    )


    if ($PSBoundParameters.ContainsKey("Grayscale") -AND $PSBoundParameters.ContainsKey("MonochromeHue")) {
        throw [System.NotSupportedException]::new("Parameters 'Grayscale' and 'MonochromeHue' can't be used together.")
    }
    if ($PSBoundParameters.ContainsKey("Pixel") -AND $PSBoundParameters.ContainsKey("Random")) {
        throw [System.NotSupportedException]::new("Parameters 'Pixel' and 'Random' can't be used together.")
    }
    if ($PSBoundParameters.ContainsKey("MonochromeColor") -AND $PSBoundParameters.ContainsKey("MonochromeHue")) {
        throw [System.NotSupportedException]::new("Parameters 'MonochromeColor' and 'MonochromeHue' can't be used together.")
    }
    if ($PSBoundParameters.ContainsKey("BlackWhite") -AND $PSBoundParameters.ContainsKey("Grayscale")) {
        throw [System.NotSupportedException]::new("Parameters 'BlackWhite' and 'Grayscale' can't be used together.")
    }
    if ($PSBoundParameters.ContainsKey("BlackWhite") -AND $PSBoundParameters.ContainsKey("MonochromeColor")) {
        throw [System.NotSupportedException]::new("Parameters 'BlackWhite' and 'MonochromeColor' can't be used together.")
    }
    if ($PSBoundParameters.ContainsKey("BlackWhite") -AND $PSBoundParameters.ContainsKey("MonochromeHue")) {
        throw [System.NotSupportedException]::new("Parameters 'BlackWhite' and 'MonochromeHue' can't be used together.")
    }
    if ($PSBoundParameters.ContainsKey("Preset") -AND $PSBoundParameters.ContainsKey("MonochromeHue")) {
        throw [System.NotSupportedException]::new("Parameters 'Preset' and 'MonochromeHue' can't be used together.")
    }
    if ($PSBoundParameters.ContainsKey("Preset") -AND $PSBoundParameters.ContainsKey("BlackWhite")) {
        throw [System.NotSupportedException]::new("Parameters 'Preset' and 'BlackWhite' can't be used together.")
    }
    if ($PSBoundParameters.ContainsKey("Preset") -AND $PSBoundParameters.ContainsKey("MonochromeColor")) {
        throw [System.NotSupportedException]::new("Parameters 'Preset' and 'MonochromeColor' can't be used together.")
    }
    if ($PSBoundParameters.ContainsKey("Preset") -AND $PSBoundParameters.ContainsKey("Grayscale")) {
        throw [System.NotSupportedException]::new("Parameters 'Preset' and 'MonochromeHue' can't be used together.")
    }

    if ($Clipboard) {
        if (![System.Windows.Clipboard]::ContainsImage()) {
            throw  [System.InvalidOperationException]::new("Clipboard doesn't contain an image")
        }

        $stream = [System.IO.MemoryStream]::new()
        $data = [System.Windows.Clipboard]::GetImage()
        $frame = [System.Windows.Media.Imaging.BitmapFrame]::Create($data)
        $encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()

        $encoder.Frames.Add($frame)
        $encoder.save($stream)
        $Image = [System.Drawing.Bitmap]::new($stream)
    }
    
    elseif ($PSBoundParameters.ContainsKey("File")) {
        $path = Join-Path -Path (Get-Location).Path -ChildPath $File
        $Image = [System.Drawing.Image]::FromFile($path)
    }

    elseif ($PSBoundParameters.ContainsKey("Testimage")) {
        $base64 = (Get-ConsoleTestImages)[$Testimage]
        $bytes = [System.Convert]::FromBase64String($base64)
        $stream = [System.IO.MemoryStream]::New($bytes)
        $Image = [System.Drawing.Image]::FromStream($stream, $true)
    }

    elseif ($PSBoundParameters.ContainsKey("base64")) {
        $bytes = [System.Convert]::FromBase64String($base64)
        $stream = [System.IO.MemoryStream]::New($bytes)
        $Image = [System.Drawing.Image]::FromStream($stream, $true)
    }

    elseif (!$PSBoundParameters.ContainsKey("Image")) {
        throw [System.NotSupportedException]::new("Please provde a testimage, a path, an image or a base64-encoded-image.")
    }

   
    # I draw a pixel with two spaces, so only half of the total width. 
    $MaxWidth = [System.Math]::Floor($host.UI.RawUI.BufferSize.Width / 2) 
    $MaxHeight = $host.UI.RawUI.BufferSize.Height
    $ratio = $Image.Width / $Image.Height

    if ($Width -GT $MaxWidth) {
        throw [System.InvalidOperationException]::New("Width must not exceed buffer-size.")
    }


    if ($Stretch) {
        $Width = $MaxWidth
        $Height = $Width * (1 / $ratio)
    }
    elseif ($Height -LE 0 -AND $Width -GT 0) {
        $Height = $Width * (1 / $ratio)
    }
    elseif ($Height -GT 0 -AND $Width -LE 0) {
        $Width = $Height * $ratio
    }
    elseif ($Height -LE 0 -AND $Width -LE 0) {

        if ($MaxHeight * $ratio -LE $MaxWidth) {
            $Height = $MaxHeight
            $Width = $Height * $ratio
        }
        else {
            $Width = $MaxWidth
            $Height = $Width * (1 / $ratio)
        }
        
    }


    
    $temp = $Image
    $Image = [System.Drawing.Bitmap]::new($Width, $Height)
    $graphics = [System.Drawing.Graphics]::FromImage($Image)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.DrawImage($temp, 0, 0, $Image.Width, $Image.Height)


    <#
        NOTE:
        https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797#rgb-colors
        
        [System.Console]::Write()
        custom foreground: `e[38;2;R;G;Bm
        custom background: `e[48;2;R;G;Bm
        move cursor: `e[<row>;<column>H
        clear screen: `e[2J
    #>

    if ($PSBoundParameters.ContainsKey("MonochromeColor")) {
        switch ($MonochromeColor) {

            Red {
                $MonochromeHue = 0
            }

            Orange {
                $MonochromeHue = 30
            }

            Yellow {
                $MonochromeHue = 60
            }

            Green {
                $MonochromeHue = 120
            }

            Cyan {
                $MonochromeHue = 180
            }

            Blue {
                $MonochromeHue = 240
            }

            Violett {
                $MonochromeHue = 270
            }

            Magenta {
                $MonochromeHue = 300
            }

            Default {
                throw [System.NotSupportedException]::new("Parameters '$MonochromeColor' is not valid.")
            }
        }
    }
    elseif ($PSBoundParameters.ContainsKey("Preset")) {
        switch ($Preset) {

            Sepia {
                $MonochromeHue = 30
                $Saturation = .2
                $Brightness = 2.5
            }

            Default {
                throw [System.NotSupportedException]::new("Parameters '$MonochromeColor' is not valid.")
            }
        }
    }


    $imageOffset = $MaxWidth - $Image.Width - 2
    $imageOffset = [System.Convert]::ToInt32($imageOffset)
    $imageOffset = [System.Math]::Max($imageOffset, 0)


    $isInvisible = [System.Char]::IsControl($Pixel[0]) -OR [System.Char]::IsWhiteSpace($Pixel[0]) # Should hopefully cover most
    $drawMode = $isInvisible -AND !$Random ? 48 : 38 # Draw visible characters as foreground and invisible as background  
    $BackgroundColor = [System.Management.Automation.PSStyle+BackgroundColor]::new()."$Background"
    
    $pixelCharacters = $Pixel.Length -EQ 1 ? "$Pixel$Pixel" : $Pixel
    $alphaCharacters = "  "    
    
    for ($row = 0; $row -LT $Image.Height; $row += 1) {

        $characters = @()
        if ($Center -AND $imageOffset -GT 0) {
            $characters += 0..$imageOffset | ForEach-Object { ' ' }
        }

        if ($drawMode -EQ 38 -AND $PSBoundParameters.ContainsKey("Background")) {
            # Make background black for better contrast, when draw mode is set to foreground
            $characters += $BackgroundColor
        }


        for ($col = 0; $col -LT $Image.Width; $col++) {
            $imagePixel = $Image.GetPixel($col, $row)

            if ($PSBoundParameters.ContainsKey('Preset') -OR $PSBoundParameters.ContainsKey("MonochromeColor") -OR $PSBoundParameters.ContainsKey("MonochromeHue")) {
                $ConvertedRGB = ConvertTo-RGB -Hue $MonochromeHue -Saturation 1 -Value 1
                $RedPercent = $ConvertedRGB.R / 255
                $GreenPercent = $ConvertedRGB.G / 255
                $BluePercent = $ConvertedRGB.B / 255
                $imagePixel = [System.Drawing.Color]::FromArgb(
                    $imagePixel.A,
                    $imagePixel.R * $RedPercent, 
                    $imagePixel.G * $GreenPercent, 
                    $imagePixel.B * $BluePercent
                )
            }

            if ($PSBoundParameters.ContainsKey('Preset') -OR $PSBoundParameters.ContainsKey('Saturation') -OR $PSBoundParameters.ContainsKey('Brightness')) {
                $SaturationCalculated = $imagePixel.GetSaturation() * ($Null -NE $Saturation ? $Saturation : 1)
                $BrightnessCalculated = $imagePixel.GetBrightness() * ($Null -NE $Brightness ? $Brightness : 1)
                $SaturationCalculated = [System.Math]::Min([System.Math]::Max($SaturationCalculated, 0), 1)
                $BrightnessCalculated = [System.Math]::Min([System.Math]::Max($BrightnessCalculated, 0), 1)
                $imagePixel = ConvertTo-RGB -Hue $imagePixel.GetHue() -Saturation $SaturationCalculated -Value $BrightnessCalculated -Alpha $imagePixel.A
            }

            if ($Random) {
                $randomChar1 = [System.Convert]::ToChar((Get-Random -Minimum 32 -Maximum 127))
                $randomChar2 = [System.Convert]::ToChar((Get-Random -Minimum 32 -Maximum 127))
                $pixelCharacters = "$randomChar1$randomChar2"
            }
            

            # Simluate alpha-channel by drawing pixel in terminal background color or background color.
            if ($imagePixel.A -LT $AlphaTrs -AND !$NoAlpha) {
                $characters += $PSBoundParameters.ContainsKey("Background") ? "$BackgroundColor$alphaCharacters" : "`e[0m$alphaCharacters"
            }

        
            # Draw pixels in grayscale.
            elseif ($Grayscale) {
                # According to Rec. 601 Luma-Coefficients
                # https://en.wikipedia.org/wiki/Luma_(video)#Rec._601_luma_versus_Rec._709_luma_coefficients

                # Putting the link here for anyone, just to be clear these numbers really mean something,
                # regarding the eyes different sensitvities to the colors and aren't randomly out of my head. 😅
                # https://en.wikipedia.org/wiki/Grayscale#Luma_coding_in_video_systems
                $grey = [System.Math]::Round($imagePixel.R * 0.299 + $imagePixel.G * 0.587 + $imagePixel.B * 0.114)
                $characters += [System.String]::Format(
                    # Append an empty space two times, since it doesn't draw squares and 2/1 looks more squary.
                    "`e[{0};2;{1};{2};{3}m{4}", $drawMode, $grey, $grey, $grey, $pixelCharacters
                )
            }

            elseif ($PSBoundParameters.ContainsKey("BlackWhite")) {
                $luma = [System.Math]::Round($imagePixel.R * 0.299 + $imagePixel.G * 0.587 + $imagePixel.B * 0.114)
                if ($luma -GT $BlackWhite) {
                    $characters += [System.String]::Format(
                        # Append an empty space two times, since it doesn't draw squares and 2/1 looks more squary.
                        "`e[{0};2;{1};{2};{3}m{4}", $drawMode, 255, 255, 255, $pixelCharacters
                    )
                }
                else {
                    $characters += [System.String]::Format(
                        # Append an empty space two times, since it doesn't draw squares and 2/1 looks more squary.
                        "`e[{0};2;{1};{2};{3}m{4}", $drawMode, 0, 0, 0, $pixelCharacters
                    )
                }
            }
                        
            # Draw pixels in their normal colors.
            else {
                $characters += [System.String]::Format(
                    # Append an empty space two times, since it doesn't draw squares and 2/1 looks more squary.
                    "`e[{0};2;{1};{2};{3}m{4}", $drawMode, $imagePixel.R, $imagePixel.G, $imagePixel.B, $pixelCharacters
                )
            }
        }


        $line = $characters -join ''
        $line += "`e[0m`n"
        #[System.Console]::Write($line)
        Write-Host -NoNewline $line # Write-Host supports emojies
        if ($Delay -GT 0) {
            Start-Sleep -Milliseconds $Delay
        }
    } 

}