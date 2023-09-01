

<#
    .SYNOPSIS
    This is a test how much is achievable with the powershell terminal.

    .DESCRIPTION
    This is a test how much is achievable with the powershell terminal.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS

      ~U~
       ' 
       v 
        


          v


#>

function Start-InvadersGame {

    [CmdletBinding(
        #DefaultParameterSetName = "difficultyLevels"
    )]
    param (
        [Parameter(
            Position = 1,
            Mandatory = $false,
            ParameterSetName = "tickIntervall"
        )]
        [ValidateRange(50, 1000)]
        [System.Int32]
        $TickIntervall = 1,


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


        [Parameter(
            Mandatory = $false
        )]
        [PSCustomObject]
        $Characters = @{}
    )

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

    $WindowHeight = $host.UI.RawUI.WindowSize.Height
    $WindowWidth = $host.UI.RawUI.WindowSize.Width

    [System.Console]::Clear()
    [System.Console]::WriteLine()
    [System.Console]::CursorVisible = $false


    $EmptyTile = ' '
    $InvaderShip = [PSCustomObject]@{

        position     = [System.Numerics.Vector2]::new(
            [System.Math]::Round($WindowWidth / 2 - 2), 0
        )
        lastPosition = $null
        blasts       = @()
        isDead       = $false


        # Gunmount postition offset from upper left start of ship.
        # This is were all ship blasts will orginate from. 
        cooldown     = 0 # ticks
        #gunmount     = [System.Numerics.Vector2]::new(1, 2) 
        #canvas       = @(
        #    '~U~',
        #    " ' "
        #)

        # Trying more complex ship design
        #gunmount     = [System.Numerics.Vector2]::new(2, 4)
        #canvas       = @(
        #    'U u U',
        #    '[{*}]',
        #    ' \|/ ',
        #    "  +  "
        #)

        gunmount     = [System.Numerics.Vector2]::new(3, 4)
        canvas       = @(
            'U  u  U',
            '[~{*}~]',
            "'``\|/´'", # The first backtick is used for escaping second and won't be displayed
            "   '   "
        )
    }

    # Referencable script block to draw elements
    $draw = {
        param($object)
        $canvas = $object.canvas
        $position = $object.position
        $lastPosition = $object.lastPosition

        $roundedX = [System.Math]::Round($position.X)
        $roundedY = [System.Math]::Round($position.y)

        # Check if a list position exists.
        if ($null -NE $lastPosition) {
            $roundedLastX = [System.Math]::Round($lastPosition.X)
            $roundedLastY = [System.Math]::Round($lastPosition.y)

            if ($roundedX -EQ $roundedLastX -AND $roundedY -EQ $roundedLastY) {
                return # only redraw when the acutal drawn position changes
            }

            # Overwrite old position
            for ($index = 0; $index -LT $canvas.Count; $index++) {
                [System.Console]::SetCursorPosition($roundedLastX, $roundedLastY + $index)
                $emptyLine = Get-LineOfChars -Length $canvas[$index].length -Char $EmptyTile
                [System.Console]::Write($emptyLine)
            }
        }

        $object.lastPosition = [System.Numerics.Vector2]::new($roundedX, $roundedY)

        if ($roundedY -GT $WindowHeight - 2) {
            # Mark as dead when an obejct leaves the window and don't redraw it.
            $object.isDead = $true
        }
        else {
            # Draw object on new position
            for ($index = 0; $index -LT $canvas.Count; $index++) {
                [System.Console]::SetCursorPosition($roundedX, $roundedY + $index)
                [System.Console]::Write($canvas[$index])
            }
        }
    }

    ########################################################
    ###### The loop for moving and drawing the snake

    $gameEndingMessage = $null

    :GameLoop
    do {
        
        Invoke-Command $draw -ArgumentList $InvaderShip

        # Update and draw blasts.
        foreach ($blast in $InvaderShip.blasts) {

            $blast.position = [System.Numerics.Vector2]::Add($blast.position, $blast.velocity)

            Invoke-Command $draw -ArgumentList $blast
        }

        # Sort out expired blasts. Also ensure it stays an array by casting.
        $InvaderShip.blasts = [PSCustomObject[]]($InvaderShip.blasts | Where-Object -Property isDead -NE $true)
        $InvaderShip.cooldown = [System.Math]::Max(0, $InvaderShip.cooldown - 1)
        
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

                $InvaderShip.position = [System.Numerics.Vector2]::new(
                    $InvaderShip.position.x - 1, $InvaderShip.position.y
                )
                break;
            }

            { $_ -in @([System.ConsoleKey]::D, [System.ConsoleKey]::RightArrow) } {

                $InvaderShip.position = [System.Numerics.Vector2]::new(
                    $InvaderShip.position.x + 1, $InvaderShip.position.y
                )
                break;
            }

            
            { $_ -in @([System.ConsoleKey]::Spacebar) } {

                if ($InvaderShip.cooldown -GT 0) {
                    break;
                }

                $InvaderShip.cooldown = 50 # Ticks
                $InvaderShip.blasts += [PSCustomObject]@{
                    position     = [System.Numerics.Vector2]::Add($InvaderShip.position, $InvaderShip.gunmount)
                    lastPosition = $null
                    velocity     = [System.Numerics.Vector2]::new(0, 0.1)
                    isDead       = $false
                    canvas       = @(
                        'v'
                    )
                }
                break;
            }


            # Disregard other inputs
            Default {}
        }

    } while ($null -EQ $keyEvent -OR $keyEvent.Key -NE [System.ConsoleKey]::Escape)

    [System.Console]::SetCursorPosition($InvaderShip.position.x, $InvaderShip.position.y + 2)
    [System.Console]::Write("Press any key to continue...")
    $null = [System.Console]::ReadKey($true)
}


    