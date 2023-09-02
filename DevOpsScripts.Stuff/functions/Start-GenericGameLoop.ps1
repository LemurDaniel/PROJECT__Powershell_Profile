

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
                param($GameObjects, $GameWidth, $GameHeight)

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
            # Objects get drawn in that order. Following objects will potentially hide previous objects.

            [ordered]@{

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
        [System.Collections.Specialized.OrderedDictionary]
        $GameObjects,



        # A customizable script-block for handeling key event. 
        # Gets called on every input, provding the key event, as well as the hashtable of gameobjects.
        # Invidual Game Objects can be access by their defined name corresponding to the key in the hashtable.
        <#
        {
            param($KeyEvent, $GameObjects, $GameWidth, $GameHeight)

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

    $EMPTY_TILE = ' '

    ################################################################################################################
    ###### Script block for updating elements gets called on each object every tick.

    $update = {
        param($object)

        # Skip any dead objects.
        if ($object.isDead) {
            return
        }

        if ($null -EQ $object.position) {
            throw "Object '$($object.name)' doesn't have a position."
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
            # $object.lastPosition = [System.Numerics.Vector2]::new($object.position.x, $object.position.y)
            $object.position = [System.Numerics.Vector2]::add($object.position, $object.velocity)
        }


        # In case th
        $WindowHeight = $host.UI.RawUI.WindowSize.Height

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
        param($object)

        if ($null -EQ $object.canvas) {
            throw "Object '$($object.name)' doesn't have a canvas array defining its shape."
        }

        if ($null -EQ $object.collisionMark) {
            $null = $object
            | Add-Member -MemberType NoteProperty -Force -Name collisionMark -Value $false
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


        # Objects wich previously collided with other objects get redrawn for correct appearance.
        if (!$object.alwaysDraw -AND !$object.collisionMark) {
            if (!$initalDraw) {
                $object.initialDraw = $true
            }
            elseif ($roundedX -EQ $roundedLastX -AND $roundedY -EQ $roundedLastY) {
                return # skip redrawing elements whose position hasn't change.
            }
        }

        # Redraw Empty-Tiles on the old position.
        for ($index = 0; $index -LT $canvas.Count; $index++) {

            # This ignores and offsets any empty tile at the start of the currents canva's line of the object.
            $emptyOffset = $canvas[$index].Length - $canvas[$index].TrimStart().Length

            $trimedLine = $canvas[$index].Trim()

            [System.Console]::SetCursorPosition($roundedLastX + $emptyOffset, $roundedLastY + $index)
            $emptyLine = Get-LineOfChars -Length $trimedLine.length -Char $EMPTY_TILE
            [System.Console]::Write($emptyLine)
        }

        # Last position get update after redraw. It is only necessary for the overdrawing with empty tiles.
        $object.lastPosition = [System.Numerics.Vector2]::new($position.x, $position.y)
        
        # Draw object on new position only if it's not dead.
        if ($object.isDead) {
            return 
        }
        
        for ($index = 0; $index -LT $canvas.Count; $index++) {

            # This ignores and offsets any empty tile at the start of the currents canva's line of the object.
            $emptyOffset = $canvas[$index].Length - $canvas[$index].TrimStart().Length

            $trimedLine = $canvas[$index].Trim()

            [System.Console]::SetCursorPosition($roundedX + $emptyOffset, $roundedY + $index)
            [System.Console]::Write($trimedLine)
        }
        
        
    }


    ################################################################################################################
    ###### Script block for processing all tiles that an object occupies.

    $processOccupiedSpace = {
        param($object, $hashTable)

        # Skip any dead objects.
        if ($object.isDead) {
            return
        }
        
                
        for ($row = 0; $row -LT $object.canvas.Count; $row++) {
            for ($col = 0; $col -LT $object.canvas[$row].Length; $col++) {

                if ($object.canvas[$row][$col] -EQ $EMPTY_TILE) {
                    continue; # Skip any empty tile for the collision check.
                }

                $tilePosition = [System.Numerics.Vector2]::new(
                    ($object.position.x + $col), ($object.position.y + $row) 
                )
                if ($hashTable.ContainsKey($tilePosition)) {
                    $hashTable[$tilePosition].objects += $object
                }
                else {
                    $hashTable[$tilePosition] = [PSCustomObject]@{
                        position = $tilePosition
                        objects  = [PSCustomObject[]]@($object)
                    }
                }

            }
        }

    }

    ################################################################################################################
    ###### The Gameloop processing and drawing all objects on each tick.

    # NOTE
    # This will be a hastable containing all positions with an array of GameObjects occupying that space.
    # All positions with more than one occupants are colliding with each other 
    $CollisionHashTable = [System.Collections.Hashtable]::new()

    # Gameobjects and their colliding participants
    $collisionsGrouped = [System.Collections.Hashtable]::new()

    try {
        $gameEndingMessage = $null

        :GameLoop
        do {

            $GameHeight = $host.UI.RawUI.WindowSize.Height
            $GameWidth = $host.UI.RawUI.WindowSize.Width

            $CollisionHashTable.clear()



            # Call the script block for updating custom parameters on each tick.
            $null = Invoke-Command -ScriptBlock $onEveryTickDo -ArgumentList $GameObjects, $GameWidth, $GameHeight

            # Only process key events when a key was pressed
            if ([System.Console]::KeyAvailable) {
                $keyEvent = [System.Console]::ReadKey($true)
                $null = Invoke-Command -ScriptBlock $onKeyEvent -ArgumentList $keyEvent, $GameObjects, $GameWidth, $GameHeight
            }
 
            # Key events are processed before each update and draw.
            foreach ($objectName in $GameObjects.Keys) {

                $objectData = $GameObjects[$objectName]

                # If it's a list, draw each individual obecjt.
                if ($objectData -is [PSCustomObject[]] -OR $objectData -is [System.Object[]]) {

                    for ($index = 0; $index -LT $objectData.Count; $index++) {
                        $null = $objectData[$index] | Add-Member -MemberType NoteProperty -Force -Name Name -Value "$objectName-$index"
                        Invoke-Command -ScriptBlock $update -ArgumentList $objectData[$index]
                        Invoke-Command -ScriptBlock $draw -ArgumentList $objectData[$index]
                        Invoke-Command -ScriptBlock  $processOccupiedSpace -ArgumentList $objectData[$index], $CollisionHashTable
                    }
                }

                # If it's an object, only draw this single object.
                elseif ($objectData -is [PSCustomObject] -OR $objectData -is [System.Object]) {
                    $null = $objectData | Add-Member -MemberType NoteProperty -Force -Name Name -Value $objectName
                    Invoke-Command -ScriptBlock $update -ArgumentList $objectData
                    Invoke-Command -ScriptBlock $draw -ArgumentList $objectData
                    Invoke-Command -ScriptBlock  $processOccupiedSpace -ArgumentList $objectData, $CollisionHashTable
                }

                # Throw error if object type is not allowed.
                else {
                    throw "$($objectData.GetType().ToString()) of '$objectName' is not allowed."
                }

            }




            # Still prototyping and testing

            # Gameobjects as keys and their collisions as objects.
            $collisionsGrouped.clear()

            $CollisionHashTable.Keys
            | Where-Object {
                $CollisionHashTable[$_].objects.Count -GT 1
            }
            | ForEach-Object { # Loops through every tile position with a collision

                $collidingObjects = $CollisionHashTable[$_].objects
                $currentPosition = $CollisionHashTable[$_].position

                # Loops through every colliding object at the current tile position
                foreach ($collider in $collidingObjects) {

                    # Mark for redrawing after collision occured.
                    $collider.collisionMark = $true

                    # Creates a collision group for the current collider if not existent.
                    if (!$collisionsGrouped.ContainsKey($collider.name)) {
                        $collisionsGrouped[$collider.name] = [PSCustomObject]@{
                            collider     = $collider
                            name         = $collider.name
                            participants = [PSCustomObject[]]@()
                            references   = [System.Collections.Hashtable]::new()
                        }
                    }

                    # The data for the currents collider collisions.
                    $collisionData = $collisionsGrouped[$collider.name]


                    # Loops through every collider at the current position, adding collision data.
                    :CollisionParticipentLoop
                    foreach ($participant in $collidingObjects) {
                        # Skip if the participant is the collider itself
                        if ($participant.name -EQ $collider.name) {
                            continue CollisionParticipentLoop
                        }

                        # If there is no collision data for the current particpant, create it.
                        if (!$collisionData.references.ContainsKey($participant.name)) {
                            $collisionData.references[$participant.name] = @{
                                objectRef = $participant
                                name      = $participant.name
                                positions = [System.Numerics.Vector2[]]@($currentPosition)
                            }
                            $collisionData.participants += $collisionData.references[$participant.name]
                        }
                        # Else add the current tile position as information about where the collisions occured.
                        elseif ($currentPosition -notin $collisionData.participants[$participant.name].positions) {
                            $collisionData.references[$participant.name].positions += $currentPosition
                        }
                    }
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

    Write-Host "`nTest ------------------------------ "
    foreach ($collider in $collisionsGrouped.Values) {

        # Testing
        Write-Host "`n'$($collider.name)' has collisions with: "
        foreach ($participant in $collider.participants) {
            Write-Host "  - '$($participant.name)' on positions: '$($participant.positions | Sort-Object)'"
        }
    }
    Write-Host "`nTest ------------------------------ "
    return
    [System.Console]::SetCursorPosition($InvaderShip.position.x, $InvaderShip.position.y + 2)
    [System.Console]::Write("Press any key to continue...")
    $null = [System.Console]::ReadKey($true)
}