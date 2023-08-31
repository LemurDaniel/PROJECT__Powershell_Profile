

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
    param (
        [Parameter(
            Mandatory = $false
        )]
        [ValidateRange(500, 1000)]
        [System.Int32]
        $TickIntervall = 750
    )

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

    $SnakeLength = 15
    $SnakeBody = 'O'
    $SnakeHead = '@'

    $WindowSize = $host.UI.RawUI.WindowSize.Width
    $GameOffsetLength = $WindowSize / 2 - $Witdh
    $OffsetLine = Get-LineOfChars $GameOffsetLength $Empty

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

    $snakeOffsetY = 1
    $snakeOffsetX = $GameOffsetLength + 2
    $velocityVector = [System.Numerics.Vector2]::new(0, 1)

    $snakePositionsMap = [System.Collections.Hashtable]::new()
    $snackPositionsMap = [System.Collections.Hashtable]::new()

    # The initial position is the center.
    $snakePositions = @([System.Numerics.Vector2]::new($Witdh / 2 , $Height / 2))

    $snakePositionsMap.add($snakePositions[0], $null)
    $gameEndingMessage = $null

    :GameLoop
    do {
        # This is the head wich moves forward
        $lastPosition = $snakePositions | Select-Object -Last 1
        $newHeadPosition = [System.Numerics.Vector2]::new($lastPosition.x + $velocityVector.x, $lastPosition.y + $velocityVector.y)


        # Draw snake head after the collision checks
        [System.Console]::SetCursorPosition($snakeOffsetX + $newHeadPosition.x, $snakeOffsetY + $newHeadPosition.y)
        [System.Console]::Write($SnakeHead)


        # Head has a different char than body. Overwrite the last head position with a body.
        $lastHeadPosition = $snakePositions | Select-Object -Last 1
        [System.Console]::SetCursorPosition($snakeOffsetX + $lastHeadPosition.X, $snakeOffsetY + $lastHeadPosition.Y)
        [System.Console]::Write($SnakeBody)
        
        # Delete last element if snake exceeds length
        if ($snakePositions.Length - 1 -GT $SnakeLength) {
            $deletePosition = $snakePositions | Select-Object -First 1
            [System.Console]::SetCursorPosition($snakeOffsetX + $deletePosition.X, $snakeOffsetY + $deletePosition.Y )
            [System.Console]::Write($Empty)

            # Delete snake tail from map and positions array
            $snakePositions = $snakePositions | Select-Object -Skip 1
            $snakePositionsMap.Remove($deletePosition)
        }

        # Check for collisions with self and wall
        if ($newHeadPosition.Y -GT $Height -OR $newHeadPosition.Y -LT 0) {
            $gameEndingMessage = 'Snake hit a Wall'
            break GameLoop
        }
        if ($newHeadPosition.X -GT $Witdh -OR $newHeadPosition.X -LT 0) {
            $gameEndingMessage = 'Snake hit a Wall'
            break GameLoop
        }
        if ($snakePositionsMap.ContainsKey($newHeadPosition)) {
            $gameEndingMessage = 'Snake hit itself'
            break GameLoop
        }

        $snakePositionsMap.add($newHeadPosition, $null)
        $snakePositions += $newHeadPosition

        [System.Console]::SetCursorPosition(0, 0)
        [System.Console]::CursorVisible = $false
        Start-Sleep -Milliseconds $TickIntervall


        ##################################################################
        ### Process key events

        # Only procss key events when a key was pressed
        if (![System.Console]::KeyAvailable) {
            continue
        }

        $keyEvent = [System.Console]::ReadKey($true)
        switch ($keyEvent.Key) {
            { $_ -in @([System.ConsoleKey]::A, [System.ConsoleKey]::LeftArrow) }  {

                # Only accept if the snake is not moving to the right
                if ($velocityVector.x -EQ 0) {
                    $velocityVector = [System.Numerics.Vector2]::new(-1, 0)
                }
                break;
            }

            { $_ -in @([System.ConsoleKey]::D, [System.ConsoleKey]::RightArrow) } {

                # Only accept if the snake is not moving to the left
                if ($velocityVector.x -EQ 0) {
                    $velocityVector = [System.Numerics.Vector2]::new(1, 0)
                }
                break;
            }

            { $_ -in @([System.ConsoleKey]::W, [System.ConsoleKey]::UpArrow) } {

                # Only accept if the snake is not moving down
                if ($velocityVector.y -EQ 0) {
                    $velocityVector = [System.Numerics.Vector2]::new(0, -1)
                }
                break;
            }
       
            { $_ -in @([System.ConsoleKey]::S, [System.ConsoleKey]::DownArrow) } {

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

    [System.Console]::SetCursorPosition($GameOffsetLength + 1, $Height + 4)
    [System.Console]::Write("Ended: $gameEndingMessage")
    [System.Console]::SetCursorPosition($GameOffsetLength + 1, $Height + 5)
    [System.Console]::Write("Press any key to continue...")
    [System.Console]::ReadKey($true)
}