

# Fun Fact: The apperently official Name for Tetris Blocks.
class Tetromino {

    static [System.Array[]]$Tetrominoes = @(
        @(
            0b0000,
            0b1111
        ),
        @(
            0b1000,
            0b1110
        ),
        @(
            0b0010,
            0b1110
        ),
        @(
            0b1100,
            0b1100
        ),
        @(
            0b0100,
            0b1110
        ),
        @(
            0b0110,
            0b1100
        ),
        @(
            0b1100,
            0b0110
        )
    )

    static [System.Windows.Media.Color[]]$Colors = @(
        [System.Windows.Media.Color]::FromArgb(255,255,255,0),
        [System.Windows.Media.Color]::FromArgb(255,0,0,0),
        [System.Windows.Media.Color]::FromArgb(0,0,255,0),
        [System.Windows.Media.Color]::FromArgb(0,255,0,0)
    )

    #################################################
    
    [System.Numerics.Vector2]$Position

    [System.Windows.Media.Color]$TetrominoColor
    [System.int16[]]$TetrominoBlock

    Tetromino($positionX, $positionY) {
        $this.Position = [System.Numerics.Vector2]::new($positionX, $positionY)
        $randomBlock  = Get-Random -Minimum 0 -Maximum ([System.int32][Tetromino]::Tetrominoes.length)
        $randomColor  = Get-Random -Minimum 0 -Maximum ([System.int32][Tetromino]::Colors.length)

        $this.TetrominoBlock = [Tetromino]::Tetrominoes[$randomBlock]
        $this.TetrominoColor = [Tetromino]::Colors[$randomColor]
    }

    [System.Void] Fall() {
        $this.Position.Y += 1
    }


    draw($Canvas, $BlockWidth) {
    
        # Always two rows and 4 columns
        for ($row = 0; $row -lt 2; $row++) {

            $bitRow = $this.TetrominoBlock[$row]
            for ($col = 0; $col -lt 4; $col++) {
                
                # From Left to right
                $hasBlock = ($bitRow -band (0b1000 -shr $col)) -gt 0

                Write-Host $hasBlock
                if($hasBlock){
                
                    $Color = [System.Windows.Media.Color]::FromArgb(255,255,255,0)
                    $SolidColorBrush = [System.Windows.Media.SolidColorBrush]::new($Color)

                    $Block = [System.Windows.Shapes.Rectangle]::new()
                    $Block.Stroke = [System.Windows.Media.Brushes]::Black
                    $Block.Fill   = $SolidColorBrush
                    $Block.StrokeThickness = 1
                
                    $Block.Width  =  $BlockWidth 
                    $Block.Height =  $BlockWidth 
            
                    $posY = $this.Position.y + ($BlockWidth * $row)
                    $posX = $this.Position.x + ($BlockWidth * $col)
                    Write-Host Test, $posX, $posY
                    [System.Windows.Media.TranslateTransform] $translate = [System.Windows.Media.TranslateTransform]::new($posX, $posY)
                    $Block.RenderTransform = $translate
                    $Canvas.Children.Add($Block)

                }
            }
        }

    }
}


function New-Tetromino {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.int32]
        $X,

        [Parameter(Mandatory = $true)]
        [System.int32]
        $Y
    )

    return [Tetromino]::new($X,$Y)
} 