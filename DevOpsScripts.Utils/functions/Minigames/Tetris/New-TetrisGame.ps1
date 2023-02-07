

class Tetris {
    
    # Width and Height
    [System.Numerics.Vector2] $Size = [System.Numerics.Vector2]::new(10, 20)

    [System.Diagnostics.Stopwatch] $GameTimer = [System.Diagnostics.Stopwatch]::new()
    [System.Windows.Threading.DispatcherTimer] $DispatcherTimer

    [System.int16[]] $GameField
    [Tetromino] $CurrentTetromino

    Tetris() {
        $this.GameField = [System.int16[]]::new($this.Size.y)
        $this.CurrentTetromino = New-TetrisBlock -X 0 -Y -1 -TetrisSize $this.Size
    }

    [System.Void] draw($Canvas) {

        $BlockWidth = [System.int32]($Canvas.ActualWidth / $this.Size.x)
        $Canvas.Height = $BlockWidth * $this.Size.Y

        $Canvas.Children.Clear()

        if ($this.CurrentTetromino.Position.Y -lt $this.Size.Y -2) {
            #Write-Host $this.CurrentTetromino.Position.Y
            $this.CurrentTetromino.Position += [System.Numerics.Vector2]::UnitY
        }
        $this.CurrentTetromino.draw($Canvas, $BlockWidth)
        
    }


    [System.Void] Start() {

        #$item = Get-ChildItem -Recurse -Filter '*tetris.xaml' | Select -first 1
        $window = New-WindowWPF -Path (Get-ChildItem -Path "$PSScriptRoot" -Recurse -Filter '*tetris.xaml') #"$PSScriptRoot/tetris.xaml"
       
        
        if ($null -eq $this.DispatcherTimer) {
            $this.GameTimer.start()
            $this.DispatcherTimer = [System.Windows.Threading.DispatcherTimer]::new()
            $this.DispatcherTimer.Interval = [timespan]::FromMilliseconds(1000)

            $Tetris = $this

            $eventHandler = {              
                $Tetris.draw($window.FindName('Canvas'))
                $window.FindName('Timer').Content = [System.String]::Format('{0:mm}:{0:ss}', $Tetris.GameTimer.Elapsed)
            }

            $keyEventHandler = {
                param($eventSender, $keyEventArgs)
                
                if ($keyEventArgs.Key -in @([System.Windows.Input.Key]::Left, [System.Windows.Input.Key]::Right)) {
                    $Tetris.CurrentTetromino.LastKeyEventBeforeTick = $keyEventArgs
                }
            }

            $Tetris.DispatcherTimer.Add_Tick($eventHandler)
            $window.Add_KeyDown($keyEventHandler)
            $window.Add_Closing({
                    $Tetris.DispatcherTimer.stop()
                    $Tetris.DispatcherTimer.Remove_Tick($eventHandler)
                    $window.Remove_KeyDown($keyEventHandler)
                })
        }
            
        $this.DispatcherTimer.start()
        $window.ShowDialog()

    }
}


function New-TetrisGame {
    param ()
    
    # Not finsihed, Distraction.
    Write-Host -Foreground GREEN '(Not finished yet) Look at the Taskbar. Window might not be focused.'
    return [Tetris]::new().Start()

}

