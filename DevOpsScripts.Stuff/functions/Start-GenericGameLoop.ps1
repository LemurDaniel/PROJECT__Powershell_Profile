

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
        [ValidateRange(1, 1000)]
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

                    (optional) collidable = $true # Passivley collidable, but generates no collision-events for itself

                    (optional) collidableWith = '*' # Activley collidable, generating collision-events.
                    (optional) collidableWith = [System.String[]]@($objectNames...) # Activley collidable, generating collision-events.)

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




        # Script block for handeling collision events.
        <#
            {
                param($collider, $participants)
            }
        #>
        [Parameter(
            Mandatory = $true
        )]
        [System.Management.Automation.ScriptBlock]
        $onCollision,
    
    
        <#
        {
            param($object, $didExitLeft, $didExitRigth, $didExitUp, $didExitDown)
        }
        #>
        [Parameter(
            Mandatory = $true
        )]
        [System.Management.Automation.ScriptBlock]
        $onExitScreen
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
    $TICK_COUNT = 0

    ################################################################################################################
    ###### Script block for updating elements gets called on each object every tick.

    $update = {
        param($object, $queue)

        # Skip any dead objects.
        if ($object.isDead) {
            return
        }

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

        $didExitDown = [System.Math]::round($object.position.y) -GT ($WindowHeight - $object.canvas.Count - 1)
        $didExitUp = [System.Math]::round($object.position.y) -LT 0
        $didExitRight = $false #[System.Math]::round($object.position.x) -GT ($WindowWidth - $object.Width)
        $didExitLeft = [System.Math]::round($object.position.x) -LT 0


        if ($didExitDown -OR $didExitUp -OR $didExitRight -OR $didExitLeft) {
            $null = Invoke-Command -ScriptBlock $onExitScreen -ArgumentList $object, $didExitLeft, $didExitRight, $didExitUp, $didExitDown
        }

        $roundedX = [System.Math]::Round($object.position.X)
        $roundedY = [System.Math]::Round($object.position.y)

        $roundedLastX = [System.Math]::Round($object.lastPosition.X)
        $roundedLastY = [System.Math]::Round($object.lastPosition.y)

        # Objects wich previously collided with other objects get redrawn for correct appearance.
        if (!$object.alwaysDraw -AND !$object.collisionMark) {
            if (!$object.initialDraw) {
                $object.initialDraw = $true
            }
            elseif ($roundedX -EQ $roundedLastX -AND $roundedY -EQ $roundedLastY) {
                return # skip redrawing elements whose position hasn't change.
            }
        }

        $null = $queue.add($object)

    }

        
    ################################################################################################################
    ###### Script block for drawing elements gets called on each object every tick.

    $draw = {
        param($object, $action)

        $WindowWidth = $host.UI.RawUI.WindowSize.Width

        $roundedX = [System.Math]::Round($object.position.X)
        $roundedY = [System.Math]::Round($object.position.y)

        $roundedLastX = [System.Math]::Round($object.lastPosition.X)
        $roundedLastY = [System.Math]::Round($object.lastPosition.y)

        $object.lastPosition = [System.Numerics.Vector2]::new($object.position.x, $object.position.y)

        # Redraw Empty-Tiles on the old position.
        for ($index = 0; $index -LT $object.canvas.Count; $index++) {

            if ($action -EQ "undraw") {

                # Allow for moving partially outside of screen with object on the left
                $offScreenOffset = 0
                if ($roundedLastX -LT 0) {
                    $offScreenOffset = [System.Math]::Abs($roundedLastX)
                } 
                #elseif($roundedLastX -GT $WindowWidth-$object.canvas[$index].Length){
                #    $offScreenOffset = 
                #}

                $substringLine = $object.canvas[$index].substring($offScreenOffset)

                # This ignores and offsets any empty tile at the start of the currents canva's line of the object.
                $emptyOffset = $substringLine.Length - $substringLine.TrimStart().Length

                [System.Console]::SetCursorPosition($roundedLastX + $emptyOffset + $offScreenOffset, $roundedLastY + $index)
                $emptyLine = Get-LineOfChars -Length $substringLine.Trim().length -Char $EMPTY_TILE
                [System.Console]::Write($emptyLine)
            }
            elseif ($action -EQ "draw") {

                # Allow for moving partially outside of screen with object
                $offScreenOffset = 0
                if ($roundedX -LT 0) {
                    $offScreenOffset = [System.Math]::Abs($roundedX)
                }

                $substringLine = $object.canvas[$index].substring($offScreenOffset)

                # This ignores and offsets any empty tile at the start of the currents canva's line of the object.
                $emptyOffset = $substringLine.Length - $substringLine.TrimStart().Length

                [System.Console]::SetCursorPosition($roundedX + $emptyOffset + $offScreenOffset, $roundedY + $index)
                [System.Console]::Write($substringLine.Trim())
                $object.collisionMark = $false
            }
        }
    }


    ################################################################################################################
    ###### Script block for processing all tiles that an object occupies.

    $processOccupiedSpace = {
        param($object, $hashTable)

        # Skip any dead objects and non-collidable objects.
        if ($object.isDead -OR $object.ignoreCollisions) {
            return
        }
        
        if ($null -NE $object.collidableWith) {
            if ($object.collidableWith -NE '*' -AND $object.collidableWith -isnot [System.String[]]) {
                throw "'$($object.name)' - collidableWith only allows for '*' or 'String[]'"
            }
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

    $drawingQueue = [System.Collections.ArrayList]::new()

    try {
        $gameEndingMessage = $null

        :GameLoop
        do {

            $GameHeight = $host.UI.RawUI.WindowSize.Height
            $GameWidth = $host.UI.RawUI.WindowSize.Width

            # Process collisions of last tick
            foreach ($collisionData in $collisionsGrouped.Values) {
                if ($collisionData.participants.Count -EQ 0) {
                    continue
                }
                Invoke-Command -ScriptBlock $onCollision -ArgumentList ($collisionData.collider), ($collisionData.participants)
            }

            $collisionsGrouped.clear()
            $CollisionHashTable.clear()
            $drawingQueue.Clear()

            # Call the script block for updating custom parameters on each tick.
            $null = Invoke-Command -ScriptBlock $onEveryTickDo -ArgumentList $GameObjects, $GameWidth, $GameHeight

            # Only process key events when a key was pressed
            if ([System.Console]::KeyAvailable) {
                $keyEvent = [System.Console]::ReadKey($true)
                $null = Invoke-Command -ScriptBlock $onKeyEvent -ArgumentList $keyEvent, $GameObjects, $GameWidth, $GameHeight
            }
 
            # Key events are processed before each update and draw.
            foreach ($objectName in ([System.String[]]$GameObjects.Keys) ) {

                $objectData = $GameObjects[$objectName]

                # If it's a list, draw each individual obecjt.
                if ($objectData -is [PSCustomObject[]] -OR $objectData -is [System.Object[]]) {

                    $processedList = [PSCustomObject]@()
                    for ($index = 0; $index -LT $objectData.Count; $index++) {
                        $null = $objectData[$index] | Add-Member -MemberType NoteProperty -Force -Name ParentName -Value $objectName
                        $null = $objectData[$index] | Add-Member -MemberType NoteProperty -Force -Name Name -Value "$objectName[$index]"
                        Invoke-Command -ScriptBlock $update -ArgumentList $objectData[$index], $drawingQueue
                        Invoke-Command -ScriptBlock  $processOccupiedSpace -ArgumentList $objectData[$index], $CollisionHashTable
                        if (!$objectData[$index].isDead) {
                            $processedList += $objectData[$index]
                        }
                    }
                    $GameObjects[$objectName] = $processedList
                }

                # If it's an object, only draw this single object.
                elseif ($objectData -is [PSCustomObject] -OR $objectData -is [System.Object]) {
                    $null = $objectData | Add-Member -MemberType NoteProperty -Force -Name Name -Value $objectName
                    Invoke-Command -ScriptBlock $update -ArgumentList $objectData, $drawingQueue
                    Invoke-Command -ScriptBlock $processOccupiedSpace -ArgumentList $objectData, $CollisionHashTable
                }

                # Throw error if object type is not allowed.
                else {
                    throw "$($objectData.GetType().ToString()) of '$objectName' is not allowed."
                }

            }


            # Make sure to undraw all objects, before starting to draw objects. To fix a bug.
            foreach ($object in $drawingQueue) {
                Invoke-Command -ScriptBlock $draw -ArgumentList $object, "undraw"
            }
            foreach ($object in $drawingQueue) {
                if (!$object.isDead) {
                    Invoke-Command -ScriptBlock $draw -ArgumentList $object, "draw"
                }
            }


            # Still prototyping and testing

            $CollisionHashTable.Keys
            | Where-Object {
                $CollisionHashTable[$_].objects.Count -GT 1
            }
            | ForEach-Object { # Loops through every tile position with a collision

                $collidingObjects = $CollisionHashTable[$_].objects
                $currentPosition = $CollisionHashTable[$_].position

                # Loops through every colliding object at the current tile position
                :colliderLoop
                foreach ($collider in $collidingObjects) {

                    # Mark for redrawing after collision occured.
                    $collider.collisionMark = $true

                    # if only passively collidable, generate no collision events.
                    if ($null -EQ $collider.collidableWith) {
                        continue colliderLoop
                    }

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

                        $nonIndexName = $participant.name -replace '\[\d+\]$', ''
                        if ($collider.collidableWith -NE '*' -AND $nonIndexName -notin $collider.collidableWith) {
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
            $TICK_COUNT = $TICK_COUNT + 1

        } while ($null -EQ $keyEvent -OR $keyEvent.Key -NE [System.ConsoleKey]::Escape)

    }
    catch {
        Write-Error $_
    }
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