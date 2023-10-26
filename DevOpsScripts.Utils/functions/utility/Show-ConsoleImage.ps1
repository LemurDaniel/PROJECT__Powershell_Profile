
<#
    .SYNOPSIS
    Attempts to draw an image onto the Terminal-Console.

    .DESCRIPTION
    Attempts to draw an image onto the Terminal-Console.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS

    .EXAMPLE

    Draw a base64 encoded image to the center of the console

    PS> Show-ConsoleImage -Base64 "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"

    .EXAMPLE

    Draw a base64 encoded image to the console, covering the whole width, but preserving ratio:

    PS> Show-ConsoleImage -Center -Stretch -Base64 "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"

    .EXAMPLE

    Draw a base64 encoded image to the console without the alpha channel:

    PS> Show-ConsoleImage -Center -NoAlpha -Base64 "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"

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
        $Grayscale
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

    elseif ($PSBoundParameters.ContainsKey("base64")) {
        $bytes = [System.Convert]::FromBase64String($base64)
        $stream = [System.IO.MemoryStream]::New($bytes)
        $Image = [System.Drawing.Image]::FromStream($stream, $true)
    }

    elseif (!$PSBoundParameters.ContainsKey("Image")) {
        throw [System.NotSupportedException]::new("Please provde a path, an image or a base64-encoded-image.")
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

    
    for ($row = 0; $row -LT $Image.Height; $row += 1) {

        $characters = @()
        if ($Center -AND $imageOffset -GT 0) {
            $characters += 0..$imageOffset | ForEach-Object { ' ' }
        }

        for ($col = 0; $col -LT $Image.Width; $col++) {
            $pixel = $Image.GetPixel($col, $row)

            if ($pixel.A -LT $AlphaTrs -AND !$NoAlpha) {
                # Simluate alpha-channel by drawing pixel in terminal background.
                $characters += "`e[0m  "
            }
            elseif ($Grayscale) {
                # According to Rec. 601 Luma-Coefficients
                # https://en.wikipedia.org/wiki/Luma_(video)#Rec._601_luma_versus_Rec._709_luma_coefficients
                $grey = [System.Math]::Round($pixel.R * 0.299 + $pixel.G * 0.587 + $pixel.B * 0.114)
                $characters += [System.String]::Format(
                    # Append an empty space two times, since it doesn't draw squares and 2/1 looks more squary
                    "`e[48;2;{0};{1};{2}m  ", $grey, $grey, $grey
                )
            }
            else {
                $characters += [System.String]::Format(
                    # Append an empty space two times, since it doesn't draw squares and 2/1 looks more squary
                    "`e[48;2;{0};{1};{2}m  ", $pixel.R, $pixel.G, $pixel.B
                )
            }
        }

        $line = $characters -join ''
        $line += "`e[0m`n"
        [System.Console]::Write($line)

        if ($Delay -GT 0) {
            Start-Sleep -Milliseconds $Delay
        }
    } 

}