

<#
    .SYNOPSIS
    (NOT FINISHED YET)
    Runs a generic game loop for managing and drawing interatctive objects in the Terminal.

    .DESCRIPTION
    (NOT FINISHED YET)
    Runs a generic game loop for managing and drawing interatctive objects in the Terminal.
    This is supposed to be a generic helper function to create different interactive Terminal-Games.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS
    None

    .EXAMPLE

    PS> Start-InvadersGame:

                 U u U
                [~{T}~]
                 `\|/´
                   Y

                   O
                   V

 

 

                          O
                          V



    .EXAMPLE
#>

function Start-GenericGameLoop {

    [CmdletBinding()]
    param (
        [Parameter(
            Position = 1,
            Mandatory = $false
        )]
        [ValidateRange(50, 1000)]
        [System.Int32]
        $TickIntervall = 1,


        # Todo Game size
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



        # A script that gets run every tick to update any custom parameters.
        <#
            {
                param($GameObjects)

                # Something...
            },
        #>
        [Parameter(
            Mandatory = $true
        )]
        [System.Management.Automation.ScriptBlock]
        $onEveryTickDo,



        # This is a hastable of all obects managed by the gameloop.
        <#
            @{

                # Template for an object to be managed
                object_name = [PSCustomObject]@{
                    # Parameters required by gameloop
                    position = [System.Numerics.Vector2]::new(0, 0) # Coordinates from upper left corner of object canvas.
                    velocity = [System.Numerics.Vector2]::new(0, 0) # optional
                    canvas   = @( # How the object is dran in the terminal. Each line of the array is a terminal line.
                        '~U~',
                        " ' "
                    ) 

                    # TODO optional value for collision handeling.
                    # - collidable_with = '*'
                    # - collidable_with = @($objectNames...)

                    # Custom parameters
                }

                # Allowed types are:
                # - [PSCustomObject]   <== A single custom object
                # - [PSCustomObject[]] <== A list of objects
                
            }
        #>
        [Parameter(
            Mandatory = $true
        )]
        [System.Collections.Hashtable]
        $GameObjects,



        # A customizable script-block for handeling key event. 
        # Gets called on every input, provding the key event, as well as the hashtable of gameobjects.
        # Invidual Game Objects can be access by their defined name corresponding to the key in the hashtable.
        <#
        {
            param($KeyEvent, $GameObjects)

            $InvaderShip = $GameObjects['InvaderShip']
                
            switch ($KeyEvent.Key) {

                { $_ -in @([System.ConsoleKey]::A, [System.ConsoleKey]::LeftArrow) } {
                
                    # Something...
                    break;
                }

                Default {}
            }

        }
        #>
        [Parameter(
            Mandatory = $true
        )]
        [System.Management.Automation.ScriptBlock]
        $onKeyEvent,




        # TODO a handler function called when a collision is dedected.
        [Parameter(
            Mandatory = $false
        )]
        [System.Management.Automation.ScriptBlock]
        $onCollision = {
            param($collisionParticipants)
        }
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

    [System.Console]::Clear()
    [System.Console]::WriteLine()
    [System.Console]::CursorVisible = $false


    $EmptyTile = ' '

    ################################################################################################################
    ###### Script block for updating elements gets called on each object every tick.

    $update = {
        param($object, $name)

        # Skip any dead objects.
        if ($object.isDead) {
            return
        }

        if ($null -EQ $object.position) {
            throw "Object '$name' doesn't have a position."
        }

        # Dead objects won't be drawn. 
        if ($null -EQ $object.isDead) {
            $null = $object
            | Add-Member -MemberType NoteProperty -Force -Name isDead -Value $false
        }

        # This is just to add a possibly non-existen properties as $null.
        if ($null -EQ $object.velocity) {
            $null = $object
            | Add-Member -MemberType NoteProperty -Force -Name velocity -Value $null
        }

        if ($null -EQ $object.lastPosition) {
            $null = $object
            | Add-Member -MemberType NoteProperty -Force -Name lastPosition -Value $null
        }


        # At this point velocity is definitly a property of $object. If it's $null won't be processed.
        if ($null -NE $object.velocity) {
            # Also update the last position if the position changes here.
            # $object.lastPosition = [System.Numerics.Vector2]::new($object.postition.x, $object.postition.y)
            $object.position = [System.Numerics.Vector2]::add($object.position, $object.velocity)
        }


        # In case th
        $WindowHeight = $host.UI.RawUI.WindowSize.Height
        $WindowWidth = $host.UI.RawUI.WindowSize.Width

        # Mark as dead when an obejct leaves the window.
        if (([System.Math]::round($object.position.y)) -GT ($WindowHeight - 2)) {
            $object.isDead = $true
        }

        #if ($name -like "InvaderShip_Blasts*") {
        #    Write-Host ([System.Math]::round($object.position.y)), ($WindowHeight - 2), $object.isDead
        #}

    }

        
    ################################################################################################################
    ###### Script block for drawing elements gets called on each object every tick.

    $draw = {
        param($object, $name)

        if ($null -EQ $object.canvas) {
            throw "Object '$name' doesn't have a canvas array defining its shape."
        }

        if ($null -EQ $object.initialDraw) {
            $null = $object
            | Add-Member -MemberType NoteProperty -Force -Name initialDraw -Value $false
        }

        $canvas = $object.canvas
        $position = $object.position
        $lastPosition = $object.lastPosition
        $initalDraw = $object.initialDraw

        $roundedX = [System.Math]::Round($position.X)
        $roundedY = [System.Math]::Round($position.y)

        $roundedLastX = [System.Math]::Round($lastPosition.X)
        $roundedLastY = [System.Math]::Round($lastPosition.y)

        if ($roundedX -EQ $roundedLastX -AND $roundedY -EQ $roundedLastY) {
            if ($initalDraw) {
                return # Only redraw when the acutal drawn position changes and their was an initial draw.
            }
            else {
                $object.initialDraw = $true
            }
        }


        # Redraw Empty-Tiles on the old position.
        for ($index = 0; $index -LT $canvas.Count; $index++) {
            [System.Console]::SetCursorPosition($roundedLastX, $roundedLastY + $index)
            $emptyLine = Get-LineOfChars -Length $canvas[$index].length -Char $EmptyTile
            [System.Console]::Write($emptyLine)
        }

        # Last position get update after redraw. It is only necessary for the overdrawing with empty tiles.
        $object.lastPosition = [System.Numerics.Vector2]::new($position.x, $position.y)
        
        if (!$object.isDead) {
            # Draw object on new position only if it's not dead.
            for ($index = 0; $index -LT $canvas.Count; $index++) {
                [System.Console]::SetCursorPosition($roundedX, $roundedY + $index)
                [System.Console]::Write($canvas[$index])
            }
        }
        
    }

    ################################################################################################################
    ###### The Gameloop processing and drawing all objects on each tick.

    try {
        $gameEndingMessage = $null

        :GameLoop
        do {

            # Call the script block for updating custom parameters on each tick.
            $null = Invoke-Command -ScriptBlock $onEveryTickDo -ArgumentList $GameObjects

            # Only process key events when a key was pressed
            if ([System.Console]::KeyAvailable) {
                $keyEvent = [System.Console]::ReadKey($true)
                $null = Invoke-Command -ScriptBlock $onKeyEvent -ArgumentList $keyEvent, $GameObjects
            }
 
            # Key events are processed before each update and draw.
            foreach ($objectName in $GameObjects.Keys) {

                $objectData = $GameObjects[$objectName]

                # If it's a list, draw each individual obecjt.
                if ($objectData -is [PSCustomObject[]] -OR $objectData -is [System.Object[]]) {

                    for ($index = 0; $index -LT $objectData.Count; $index++) {
                        Invoke-Command -ScriptBlock $update -ArgumentList $objectData[$index], "$objectName-$index"
                        Invoke-Command -ScriptBlock $draw -ArgumentList $objectData[$index], "$objectName-$index"
                    }
                }

                # If it's an object, only draw this single object.
                elseif ($objectData -is [PSCustomObject] -OR $objectData -is [System.Object]) {
                    Invoke-Command -ScriptBlock $update -ArgumentList $objectData, $objectName
                    Invoke-Command -ScriptBlock $draw -ArgumentList $objectData, $objectName
                }

                # Throw error if object type is not allowed.
                else {
                    throw "$($objectData.GetType().ToString()) of '$objectName' is not allowed."
                }

            }

            [System.Console]::CursorVisible = $false
            Start-Sleep -Milliseconds $TickIntervall

        } while ($null -EQ $keyEvent -OR $keyEvent.Key -NE [System.ConsoleKey]::Escape)

    }
    catch {}
    finally {
        # Always leave function with a visible cursor in case of errors.
        [System.Console]::CursorVisible = $true
    }

    [System.Console]::SetCursorPosition($InvaderShip.position.x, $InvaderShip.position.y + 2)
    [System.Console]::Write("Press any key to continue...")
    $null = [System.Console]::ReadKey($true)
}