

<#
    .SYNOPSIS
    Draws a snake game. Use UP,DOWN,LEFT,RIGHT Arrows or WASD for movement.

    .DESCRIPTION
    Draws a snake game. Use UP,DOWN,LEFT,RIGHT Arrows or WASD for movement.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS

    Snake: 10         Snacks eaten: 5
    #################################
    #                               #
    #   O                           #
    #   O                           #
    #   O                           #
    #   OOOOOO@          +          #
    #                               #
    #                               #
    #                               #
    #                               #
    #                               #
    #                               #
    #################################


    NOTE: Requires Powershell 7 or higher
#>

function Start-SnakeGame {

    [CmdletBinding(
        DefaultParameterSetName = "difficultyLevels"
    )]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $false,
            ParameterSetName = "difficultyLevels"
        )]
        [System.String]
        [ArgumentCompleter(
            {
                return @('Beginner', 'Moderate', 'Difficult', 'Challenge', 'Hardcore')
            }
        )]
        [ValidateScript(
            {
                $_ -in @('Beginner', 'Moderate', 'Difficult', 'Challenge', 'Hardcore')
            },
            ErrorMessage = "Valid diffculites: 'Beginner', 'Moderate', 'Difficult', 'Challenge', 'Hardcore'"
        )]
        $Difficulty = "Moderate",

        [Parameter(
            Position = 1,
            Mandatory = $false,
            ParameterSetName = "tickIntervall"
        )]
        [ValidateRange(50, 1000)]
        [System.Int32]
        $TickIntervall = 500,


        [Parameter(
            Mandatory = $false
        )]
        [ValidateRange(5, 50)]
        [System.Int32]
        $Height = 10,

        [Parameter(
            Mandatory = $false
        )]
        [ValidateRange(15, 150)]
        [System.Int32]
        $Witdh = 30,

        # The initial Snake length
        [Parameter(
            Mandatory = $false
        )]
        [System.Int32]
        $SnakeLength = 3,

        [Parameter(
            Mandatory = $false
        )]
        [PSCustomObject]
        $Characters = @{
            Wall       = '#'
            Empty      = ' '
        
            SnakeSnack = '+'
            SnakeBody  = 'O'
            SnakeHead  = '@'
        }
    )


    $difficultyMapping = [ordered]@{
        "Beginner"  = 500
        "Moderate"  = 350
        "Difficult" = 200
        "Challenge" = 150
        "Hardcore"  = 75
    }
    
    if ($PSBoundParameters.ContainsKey('Difficulty')) {
        $TickIntervall = $difficultyMapping[$Difficulty]
    }

    ########################################################
    ###### short internal helper function

    function Get-LineOfChars {
        param (
            [Parameter()]
            $Length,

            [Parameter()]
            $Char
        )
        
        return (1..$Length | ForEach-Object { $Char }) -join ''
    }

    ########################################################
    ###### Some initial values

    $snackedSnakeSnacks = 0

    $WindowHeight = $host.UI.RawUI.WindowSize.Height
    $WindowWidth = $host.UI.RawUI.WindowSize.Width
    $GameOffsetLength = [System.Math]::floor($WindowWidth / 2 - $Witdh / 2 - 2)
    $OffsetLine = Get-LineOfChars $GameOffsetLength $Characters.Empty


    # Height + Upper/Lower Wall + 2 lines of text below + 3 lines of text above
    $RequiredHeight = $Height + 2 + 2 + 3
    if ($WindowHeight -LT $RequiredHeight) {
        throw "Terminal Height must be at least:  $RequiredHeight (Currently: $WindowHeight)"
    }

    # Width + 2 Walls + GameOffsetLength
    $RequiredWidth = $Witdh + 2 + $GameOffsetLength
    if ($WindowWidth -LT $RequiredWidth) {
        throw "Terminal Width must be at least:  $RequiredWidth (Currently: $WindowWidth)"
    }

    ########################################################
    ###### Draw Box for snake
    $upDownWall = Get-LineOfChars ($Witdh + 2) $Characters.Wall

    [System.Console]::Clear()
    [System.Console]::WriteLine()
    [System.Console]::WriteLine()
    [System.Console]::WriteLine()
    [System.Console]::WriteLine("$OffsetLine$upDownWall")
    1..$Height | ForEach-Object {
        $emptyLine = Get-LineOfChars $Witdh $Characters.Empty
        [System.Console]::WriteLine("$OffsetLine$($Characters.Wall)$emptyLine$($Characters.Wall)")
    }
    [System.Console]::WriteLine("$OffsetLine$upDownWall")
    [System.Console]::CursorVisible = $false

    ########################################################
    ###### The loop for moving and drawing the snake

    $snakeOffsetY = 4 # Empty top row + row for difficulty + row for game stats + upper wall row
    $snakeOffsetX = $GameOffsetLength + 1 # Gameoffset + Wall
    $velocityVector = [System.Numerics.Vector2]::new(0, 1)

    $snakePositionsMap = [System.Collections.Hashtable]::new()
    # $snackPositionsMap = [System.Collections.Hashtable]::new()

    # The initial position is the center.
    $snakePositions = @([System.Numerics.Vector2]::new($Witdh / 2, $Height / 2))
    $currentSnackPosition = $null

    $snakePositionsMap.add($snakePositions[0], $null)
    $gameEndingMessage = $null

    :GameLoop
    do {
        # This is the head wich moves forward
        $lastPosition = $snakePositions | Select-Object -Last 1
        $newHeadPosition = [System.Numerics.Vector2]::new($lastPosition.x + $velocityVector.x, $lastPosition.y + $velocityVector.y)


        # Draw snake head after the collision checks
        [System.Console]::SetCursorPosition($snakeOffsetX + $newHeadPosition.x, $snakeOffsetY + $newHeadPosition.y)
        [System.Console]::Write($Characters.SnakeHead)


        # Head has a different char than body. Overwrite the last head position with a body.
        $lastHeadPosition = $snakePositions | Select-Object -Last 1
        [System.Console]::SetCursorPosition($snakeOffsetX + $lastHeadPosition.X, $snakeOffsetY + $lastHeadPosition.Y)
        [System.Console]::Write($Characters.SnakeBody)
        
        # Delete last element if snake exceeds length
        if ($snakePositions.Length -GE $SnakeLength) {
            $deletePosition = $snakePositions | Select-Object -First 1
            [System.Console]::SetCursorPosition($snakeOffsetX + $deletePosition.X, $snakeOffsetY + $deletePosition.Y )
            [System.Console]::Write($Characters.Empty)

            # Delete snake tail from map and positions array
            $snakePositions = $snakePositions | Select-Object -Skip 1
            $snakePositionsMap.Remove($deletePosition)
        }

        # Check for collisions with self and wall
        if ($newHeadPosition.Y -GE $Height -OR $newHeadPosition.Y -LT 0) {
            $gameEndingMessage = 'Snake hit a Wall'
            break GameLoop
        }
        if ($newHeadPosition.X -GE $Witdh -OR $newHeadPosition.X -LT 0) {
            $gameEndingMessage = 'Snake hit a Wall'
            break GameLoop
        }
        if ($snakePositionsMap.ContainsKey($newHeadPosition)) {
            $gameEndingMessage = 'Snake hit itself'
            break GameLoop
        }

        # Increase snake length when eating a snack
        if ($newHeadPosition.Equals($currentSnackPosition)) {
            $currentSnackPosition = $null
            $snackedSnakeSnacks += 1
            $SnakeLength += 1
        }

        $snakePositionsMap.add($newHeadPosition, $null)
        $snakePositions += $newHeadPosition


        # Spawn a new snack for the snake.
        while ($null -EQ $currentSnackPosition) {
            $proposedPosition = [System.Numerics.Vector2]::new(
                    (Get-Random -Minimum 0 -Maximum $Witdh),
                    (Get-Random -Minimum 0 -Maximum $Height)
            )

            # Snacks can only spawn on fields which are not occupied by the snake
            if (!$snakePositionsMap.ContainsKey($proposedPosition)) {
                $currentSnackPosition = $proposedPosition
            }
        }

        # Draw snake snack
        [System.Console]::SetCursorPosition($snakeOffsetX + $currentSnackPosition.X, $snakeOffsetY + $currentSnackPosition.Y )
        [System.Console]::Write($Characters.SnakeSnack)

        [System.Console]::SetCursorPosition($GameOffsetLength, 1)
        $displayDifficulty = $TickIntervall -notin $difficultyMapping.Values ? "$TickIntervall milliseconds" : $Difficulty
        [System.Console]::Write("Difficulty: $displayDifficulty")
        [System.Console]::SetCursorPosition($GameOffsetLength, 2)
        [System.Console]::Write("Snacks eaten: $snackedSnakeSnacks")
        $snakeText = "Snake: $SnakeLength"
        [System.Console]::SetCursorPosition($GameOffsetLength + 2 + $Witdh - $snakeText.Length, 2)
        [System.Console]::Write($snakeText)

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
            { $_ -in @([System.ConsoleKey]::A, [System.ConsoleKey]::LeftArrow) } {

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

    [System.Console]::SetCursorPosition($GameOffsetLength, $Height + 5)
    [System.Console]::Write("Ended: $gameEndingMessage")
    [System.Console]::SetCursorPosition($GameOffsetLength, $Height + 6)
    [System.Console]::Write("Press any key to continue...")
    $null = [System.Console]::ReadKey($true)
}



