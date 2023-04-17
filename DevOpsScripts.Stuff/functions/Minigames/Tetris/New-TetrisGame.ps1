
Using Module "./classes/Tetris.psm1"


function New-TetrisGame {
    param ()
    
    # Not finsihed, Distraction.
    Write-Host -Foreground GREEN '(Not finished yet) Look at the Taskbar. Window might not be focused.'
    return [Tetris]::new().Start()

}

