

<#
    .SYNOPSIS
    (NOT FINISHED YET).
    Draws a snake game. Use UP,DOWN,LEFT,RIGHT Arrows for movement.

    .DESCRIPTION
    (NOT FINISHED YET).
    Draws a snake game. Use UP,DOWN,LEFT,RIGHT Arrows for movement.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS

    #################################
    #                               #
    #                               #
    #                               #
    #               O               #
    #               O               #
    #               O               #
    #               @               #
    #                               #
    #                               #
    #                               #
    #                               #
    #################################


#>


function Start-SnakeGame {
    param ()

    function Get-LineOfChars {
        param (
            [Parameter()]
            $Length,

            [Parameter()]
            $Char
        )
        
        return (0..$Length | ForEach-Object { $Char }) -join ''
    }

    ########################################################
    ###### Some initial values

    $Witdh = 30
    $Height = 10

    $Wall = '#'
    $Empty = ' '

    $SnakeLength = 5
    $SnakeBody = 'O'
    $SnakeHead = '@'

    $WindowSize = $host.UI.RawUI.WindowSize.Width
    $OffsetLength = $WindowSize / 2 - $Witdh
    $OffsetLine = Get-LineOfChars $OffsetLength $Empty

    ########################################################
    ###### Draw Box for snake
    $upDownWall = Get-LineOfChars ($Witdh + 2) $Wall

    [System.Console]::Clear()
    [System.Console]::WriteLine("$OffsetLine$upDownWall")
    0..$Height | ForEach-Object {
        $emptyLine = Get-LineOfChars $Witdh $Empty
        [System.Console]::WriteLine("$OffsetLine$Wall$emptyLine$Wall")
    }
    [System.Console]::WriteLine("$OffsetLine$upDownWall")
    [System.Console]::CursorVisible = $false

    ########################################################
    ###### The loop for moving and drawing the snake

    # The initial position is the center.
    $snakePositions = @(
        [System.Numerics.Vector2]::new($Witdh / 2 , 0) #$Height / 2)
    )

    $snakeOffsetY = +1
    $snakeOffsetX = $OffsetLength + 2
    $velocityVector = [System.Numerics.Vector2]::new(0, 1)

    do {
        # This is the head wich moves forward
        $lastPosition = $snakePositions | Select-Object -Last 1
        $newHeadPosition = [System.Numerics.Vector2]::new(
            $lastPosition.x + $velocityVector.x, $lastPosition.y + $velocityVector.y
        )

        $snakePositions += $newHeadPosition
        $snakePositions | ForEach-Object { @{ x = $_.x; y = $_.y } } | ConvertTo-Json | Out-File test.json

        [System.Console]::SetCursorPosition(
            $snakeOffsetX + $newHeadPosition.x, $snakeOffsetY + $newHeadPosition.y
        )
        [System.Console]::Write($SnakeHead)

        # Head has a different char than body. Overwrite the last head position with a body.
        if ($snakePositions.Length -GT 1) {
            $lastHeadPosition = $snakePositions | Select-Object -Last 2 | Select-Object -SkipLast 1
            [System.Console]::SetCursorPosition(
                $snakeOffsetX + $lastHeadPosition.X, $snakeOffsetY + $lastHeadPosition.Y
            )
            [System.Console]::Write($SnakeBody)
        }
        
        # Delete last element if snake exceeds length
        if ($snakePositions.Length -GT $SnakeLength) {
            $deletePosition = $snakePositions | Select-Object -First 1
            $snakePositions = $snakePositions | Select-Object -Skip 1
            [System.Console]::SetCursorPosition(
                $snakeOffsetX + $deletePosition.X, $snakeOffsetY + $deletePosition.Y
            )
            [System.Console]::Write($Empty)
        }

        [System.Console]::SetCursorPosition(0, 0)
        [System.Console]::CursorVisible = $false
        Start-Sleep -Seconds 1

        [System.Console]::CursorVisible = $false

        # Check out of Bounds
        if ($newHeadPosition.Y -GE $Height -OR $newHeadPosition.Y -LT 1) {
            throw "Out of Bounds"
        }
        if ($newHeadPosition.X -GE $Witdh -OR $newHeadPosition.X -LT 1) {
            throw "Out of Bounds"
        }


        ##################################################################
        ### Process key events

        # Only procss key events when a key was pressed
        if (![System.Console]::KeyAvailable) {
            continue
        }

        $keyEvent = [System.Console]::ReadKey($true)
        switch ($keyEvent) {
            { $_.Key -EQ [System.ConsoleKey]::LeftArrow } {

                # Only accept if the snake is not moving to the right
                if ($velocityVector.x -EQ 0) {
                    $velocityVector = [System.Numerics.Vector2]::new(-1, 0)
                }
                break;
            }

            { $_.Key -EQ [System.ConsoleKey]::RightArrow } {

                # Only accept if the snake is not moving to the left
                if ($velocityVector.x -EQ 0) {
                    $velocityVector = [System.Numerics.Vector2]::new(1, 0)
                }
                break;
            }

            { $_.Key -EQ [System.ConsoleKey]::UpArrow } {

                # Only accept if the snake is not moving down
                if ($velocityVector.y -EQ 0) {
                    $velocityVector = [System.Numerics.Vector2]::new(0, -1)
                }
                break;
            }

            { $_.Key -EQ [System.ConsoleKey]::DownArrow } {

                # Only accept if the snake is not moving up
                if ($velocityVector.y -EQ 0) {
                    $velocityVector = [System.Numerics.Vector2]::new(0, 1)
                }
                break;
            }

            # Disregard other inputs
            Default {}
        }

    } while ($null -EQ $keyEvent -OR $keyEvent.Key -NE [System.ConsoleKey]::Escape)

}