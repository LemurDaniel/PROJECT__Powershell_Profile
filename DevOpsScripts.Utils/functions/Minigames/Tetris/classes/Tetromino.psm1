
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
        [System.Windows.Media.Color]::FromArgb(255, 255, 255, 0),
        [System.Windows.Media.Color]::FromArgb(255, 0, 255, 255),
        [System.Windows.Media.Color]::FromArgb(255, 0, 0, 255),
        [System.Windows.Media.Color]::FromArgb(255, 0, 255, 0),
        [System.Windows.Media.Color]::FromArgb(255, 255, 0, 0)
    )

    #################################################
    
    [System.Numerics.Vector2]$Position
    [System.Numerics.Vector2]$TetrisSize

    [System.Windows.Media.Color]$TetrominoColor
    [System.int16[]]$TetrominoBlock
    [System.Windows.Input.KeyEventArgs]$LastKeyEventBeforeTick = $null

    Tetromino($positionX, $positionY, $TetrisSize) {
        $this.TetrisSize = $TetrisSize
        $this.Position = [System.Numerics.Vector2]::new($positionX, $positionY)
        $randomBlock = Get-Random -Minimum 0 -Maximum ([System.int32][Tetromino]::Tetrominoes.length)
        $randomColor = Get-Random -Minimum 0 -Maximum ([System.int32][Tetromino]::Colors.length)

        $this.TetrominoBlock = [Tetromino]::Tetrominoes[$randomBlock]
        $this.TetrominoColor = [Tetromino]::Colors[$randomColor]
    }

    static [System.Windows.Shapes.Rectangle] drawTile($BlockWidth, $posX, $posY, $Color, $Opacity = 1) {

        $SolidColorBrush = [System.Windows.Media.SolidColorBrush]::new($Color)
        $Block = [System.Windows.Shapes.Rectangle]::new()
        $Block.Stroke = [System.Windows.Media.Brushes]::Black
        $Block.StrokeThickness = 1
        $Block.Fill = $SolidColorBrush
        $Block.Opacity = $Opacity
    
        $Block.Width = $BlockWidth 
        $Block.Height = $BlockWidth
        $Block.Effect = [System.Windows.Media.Effects.DropShadowEffect]::new()
        $Block.Effect.Color = $Color
        $Block.Effect.Opacity = 0.5

        [System.Windows.Media.TranslateTransform] $translate = [System.Windows.Media.TranslateTransform]::new($posX, $posY)
        $Block.RenderTransform = $translate
        return $Block
    }

    [System.Void] draw($Canvas, $BlockWidth) {

        if ($null -ne $this.LastKeyEventBeforeTick) {

            if ($this.LastKeyEventBeforeTick.Key -eq [System.Windows.Input.Key]::Left -AND $this.Position.X -gt 0) {
                $this.Position -= [System.Numerics.Vector2]::UnitX
            }
            elseif ($this.LastKeyEventBeforeTick.Key -eq [System.Windows.Input.Key]::Right -AND $this.Position.X -lt $this.TetrisSize.X - 2) {
                $this.Position += [System.Numerics.Vector2]::UnitX
            }

            $this.LastKeyEventBeforeTick = $null
        }
    
        # Always two rows and 4 columns
        for ($row = 0; $row -lt 2; $row++) {

            $bitRow = $this.TetrominoBlock[$row]
            for ($col = 0; $col -lt 4; $col++) {
                
                # From Left to right
                $hasBlock = ($bitRow -band (0b1000 -shr $col)) -gt 0

                if ($hasBlock) {
                    $posY = $this.Position.y * $BlockWidth + ($BlockWidth * $row)
                    $posX = $this.Position.x * $BlockWidth + ($BlockWidth * $col)
            
                    $Block = [Tetromino]::drawTile($BlockWidth, $posX, $posY, $this.TetrominoColor, 1)
                    $Canvas.Children.Add($Block)
                }
            }

        }
    }
}