

class Tetris {
    
    # Width and Height
    [System.Numerics.Vector2] $Size = [System.Numerics.Vector2]::new(10,24)
    [System.Diagnostics.Stopwatch] $GameTimer = [System.Diagnostics.Stopwatch]::new()
    [System.Windows.Threading.DispatcherTimer] $DispatcherTimer
    [System.int16[]] $GameField
    [Tetromino] $CurrentTetromino

    Tetris() {
        $this.GameField = [System.int16[]]::new($this.Size.y)
        $this.CurrentTetromino = New-Tetromino -X 0 -Y 0
    }

    [System.Void] draw($Canvas) {
        $ActualHeight = $Canvas.ActualHeight
        $ActualWidth = $Canvas.ActualWidth

        $Canvas.Children.Clear()

        $BlockWidth  = [System.int32]($ActualWidth / $this.Size.x)
        $this.CurrentTetromino.draw($Canvas, $BlockWidth)
        
    }


    [System.Void] Start() {

        $item = Get-ChildItem -Recurse -Filter '*tetris.xaml' | Select -first 1
        $window = New-WindowWPF -Path $item 
       
        
        if($null -eq $this.DispatcherTimer) {
            $this.GameTimer.start()
            $this.DispatcherTimer = [System.Windows.Threading.DispatcherTimer]::new()
            $this.DispatcherTimer.Interval = [timespan]::FromMilliseconds(1000)

            $Tetris = $this
            $this.DispatcherTimer.Add_Tick({              
                $Tetris.CurrentTetromino.Position += [System.Numerics.Vector2]::UnitY
                $Tetris.CurrentTetromino.Position
                $Tetris.draw($window.FindName('Canvas'))
                $window.FindName('Timer').Content = [System.String]::Format('{0:mm}:{0:ss}', $Tetris.GameTimer.Elapsed)
            })
        }
            
        $this.DispatcherTimer.start()
        $window.ShowDialog()

    }
}


function New-TetrisGame {
    param ()
    
    # Not finsihed, Distraction.
    return [Tetris]::new().Start()

}

