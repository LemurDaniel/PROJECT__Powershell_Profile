
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

    Draw a dog with random pixels:

    PS> Show-ConsoleImage -Center -Random -Testimage cutedog


    .EXAMPLE

    Draw an image saved in the clipboard:

    PS> Show-ConsoleImage -Stretch -Center -Clipboard

    .EXAMPLE

    Draw an image saved in the clipboard as grayscale:

    PS> Show-ConsoleImage -Stretch -Center -Grayscale -Clipboard



    .EXAMPLE

    Draw a file as an image to the console:

    PS> Show-ConsoleImage -Stretch -Center -File <autocompleted_path>

    .LINK
        
#>

function Show-ConsoleImage {

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
        
        # Set a custom character to display as a pixel.
        [Parameter()]
        [System.String]
        $Pixel = " ",

        # Print each line with a delay, because looks funny.
        [Parameter()]
        [System.int32]
        $Delay = 0,

        # Set alpha treshold
        [Parameter()]
        [System.Byte]
        $AlphaTrs = 32,
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
        $Grayscale,

        # Draw image with random characters.
        [Parameter()]
        [switch]
        $Random
    )



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

    $imageOffset = $MaxWidth - $Image.Width - 2
    $imageOffset = [System.Convert]::ToInt32($imageOffset)
    $imageOffset = [System.Math]::Max($imageOffset, 0)

    $isInvisible = [System.Char]::IsControl($Pixel[0]) -OR [System.Char]::IsWhiteSpace($Pixel[0]) # Should hopefully cover most
    $drawMode = $isInvisible -AND !$Random ? 48 : 38 # Draw visible characters as foreground and invisible as background  
    $pixelCharacters = $Pixel.Length -EQ 1 ? "$Pixel$Pixel" : $Pixel
    $alphaCharacters = "  "    
    
    for ($row = 0; $row -LT $Image.Height; $row += 1) {

        $characters = @()
        if ($Center -AND $imageOffset -GT 0) {
            $characters += 0..$imageOffset | ForEach-Object { ' ' }
        }

        for ($col = 0; $col -LT $Image.Width; $col++) {
            $imagePixel = $Image.GetPixel($col, $row)

            if ($Random) {
                $randomChar1 = [System.Convert]::ToChar((Get-Random -Minimum 32 -Maximum 127))
                $randomChar2 = [System.Convert]::ToChar((Get-Random -Minimum 32 -Maximum 127))
                $pixelCharacters = "$randomChar1$randomChar2"
            }
            
            if ($imagePixel.A -LT $AlphaTrs -AND !$NoAlpha) {
                # Simluate alpha-channel by drawing pixel in terminal background.
                $characters += "`e[0m$alphaCharacters"
            }
            elseif ($Grayscale) {
                # According to Rec. 601 Luma-Coefficients
                # https://en.wikipedia.org/wiki/Luma_(video)#Rec._601_luma_versus_Rec._709_luma_coefficients
                $grey = [System.Math]::Round($imagePixel.R * 0.299 + $imagePixel.G * 0.587 + $imagePixel.B * 0.114)
                $characters += [System.String]::Format(
                    # Append an empty space two times, since it doesn't draw squares and 2/1 looks more squary
                    "`e[{0};2;{1};{2};{3}m{4}", $drawMode, $grey, $grey, $grey, $pixelCharacters
                )
            }
            else {
                $characters += [System.String]::Format(
                    # Append an empty space two times, since it doesn't draw squares and 2/1 looks more squary
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