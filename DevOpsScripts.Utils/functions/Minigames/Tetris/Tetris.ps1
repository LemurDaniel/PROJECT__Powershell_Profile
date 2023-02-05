

class Tetris {
    
    # Width and Height
    [System.Numerics.Vector2] $Size = [System.Numerics.Vector2]::new(10,24)
    [System.Diagnostics.Stopwatch] $GameTimer = [System.Diagnostics.Stopwatch]::new()
    [System.int16[]] $GameField
    [Tetromino] $CurrentTetromino

    Tetris() {
        $this.GameField = [System.int16[]]::new($this.Size.y)
        $this.CurrentTetromino = New-Tetromino -X 0 -Y 0

        $this.GameTimer.start()
    }

    [System.Void] Tick() {
        $this.CurrentTetromino.Position += [System.Numerics.Vector2]::UnitY
        Write-Host $this.CurrentTetromino.Position
    }

    [System.Void] draw($Canvas) {
        $ActualHeight = $Canvas.ActualHeight
        $ActualWidth = $Canvas.ActualWidth

        $Canvas.Children.Clear()

        $BlockWidth  = [System.int32]($ActualWidth / $this.Size.x)
        $this.CurrentTetromino.draw($Canvas, $BlockWidth)

        Write-Host 'Hello'
    }
}


$Tetris = [Tetris]::new()
$item = Get-ChildItem -Recurse -Filter '*tetris.xaml' | Select -first 1

$window = New-WindowWPF -Path $item 

$window = New-WindowBindings -Window $window -Bind @{
    Test = @{

    }
}

$dispatcherTimer = [System.Windows.Threading.DispatcherTimer]::new()
$dispatcherTimer.Interval = [timespan]::FromMilliseconds(1000)
$dispatcherTimer.Add_Tick({ 
    
    $Tetris.Tick()
    $Tetris.draw($window.FindName('Canvas'))
    $window.FindName('Timer').Content = [System.String]::Format('{0:mm}:{0:ss}', $Tetris.GameTimer.Elapsed)
})

#$dispatcherTimer.start()
#$window.ShowDialog()

