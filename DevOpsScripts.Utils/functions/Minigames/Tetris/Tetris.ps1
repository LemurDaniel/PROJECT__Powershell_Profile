

class Tetris {
    
    # Width and Height
    [System.Numerics.Vector2] $Size = [System.Numerics.Vector2]::new(10,24)
    [System.int16[]] $GameField
    [Tetromino] $CurrentTetromino

    Tetris() {
        $this.GameField = [System.int16[]]::new($this.Size.y)
        $this.CurrentTetromino = New-Tetromino -X 0 -Y 0
    }


    draw($Canvas) {
        $ActualHeight = $Canvas.ActualHeight
        $ActualWidth = $Canvas.ActualWidth

        $Canvas.Children.Clear()

        $BlockWidth  = [System.int32]($ActualWidth / $this.Size.x)
        $this.CurrentTetromino.draw($Canvas, $BlockWidth)

        Write-Host 'Hello'
    }
}

<#
$Tetris = [Tetris]::new()
$item = Get-ChildItem -Recurse -Filter '*tetris.xaml'

$window = New-WindowWPF -Path $item 

$window = New-WindowBindings -Window $window -Bind @{
    Test = @{
    
        Add_Click = {
            $Tetris.draw($window.FindName('Canvas'))
        }
    }
}

$window.ShowDialog()

#>