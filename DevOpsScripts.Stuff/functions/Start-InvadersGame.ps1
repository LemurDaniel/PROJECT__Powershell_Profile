

<#
    .SYNOPSIS
    (NOT FINISHED YET)
    This is a test how much is achievable with the powershell terminal.

    .DESCRIPTION
    (NOT FINISHED YET)
    This is a test how much is achievable with the powershell terminal.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS

                 U u U
                [~{T}~]
                 `\|/´
                   Y

                   O
                   V

 

 

                          O
                          V

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
        $Customization = @{

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

            gunmount = [System.Numerics.Vector2]::new(3, 4)
            ship     = @(
                ' U u U ',
                '[~{T}~]',
                ' `\|/´ '
                "   Y   "
            )

            blast    = @(
                'O'
                'V'
            )
        }
    )


    # The configurations for this game
    $Configuration = @{

        # Objects get drawn in that order. Following objects will potentially hide previous objects.
        GameObjects   = [ordered]@{

            InvaderShip        = [PSCustomObject]@{
                position    = [System.Numerics.Vector2]::new(20, 0)
                canvas      = $Customization.ship

                # custom parameters
                cooldown    = 0
                gunmount    = $Customization.gunmount
                blastDesign = $Customization.blast
            }

            # Placeholder list for tracking all blasts.
            InvaderShip_Blasts = [PSCustomObject[]]@()
            BlastExplosions    = [PSCustomObject[]]@()
        }



        onEveryTickDo = {
            param($GameObects)

            # Update the gun cooldown of the spaceship.
            $GameObects['InvaderShip'].cooldown = [System.Math]::Max(0, $GameObects['InvaderShip'].cooldown - 1)

            foreach ($explosion in $GameObects['BlastExplosions']) {

                $explosion.lifetime += 1
                
                if ($explosion.lifetime -GT 10 -AND $explosion.currentStage -EQ 5) {
                    $explosion.canvas = $explosion.stages[4]
                    $explosion.redrawMark = $true
                    $explosion.currentStage = 4
                }
                elseif ($explosion.lifetime -GT 20 -AND $explosion.currentStage -EQ 4) {
                    $explosion.canvas = $explosion.stages[3]
                    $explosion.redrawMark = $true
                    $explosion.currentStage = 3
                }
                elseif ($explosion.lifetime -GT 30 -AND $explosion.currentStage -EQ 3) {
                    $explosion.canvas = $explosion.stages[2]
                    $explosion.redrawMark = $true
                    $explosion.currentStage = 2
                }
                elseif ($explosion.lifetime -GT 50 -AND $explosion.currentStage -EQ 2) {
                    $explosion.canvas = $explosion.stages[1]
                    $explosion.redrawMark = $true
                    $explosion.currentStage = 1
                }
                elseif ($explosion.lifetime -GT 70 -AND $explosion.currentStage -EQ 1) {
                    $explosion.canvas = $explosion.stages[0]
                    $explosion.redrawMark = $true
                    $explosion.currentStage = 0
                }
                elseif ($explosion.lifetime -GT 120 -AND $explosion.currentStage -EQ 0) {
                    $explosion.isDead = $true
                }
            }
        }


        
        onKeyEvent    = {
            param($KeyEvent, $GameObects)
    
            $InvaderShip = $GameObects['InvaderShip']
                
            switch ($KeyEvent.Key) {
        
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
        
                    if ( $InvaderShip.cooldown -GT 0) {
                        break;
                    }
        
                    $InvaderShip.cooldown = 50 # Ticks
                    $GameObects['InvaderShip_Blasts'] += [PSCustomObject]@{
                        position = [System.Numerics.Vector2]::Add( $InvaderShip.position, $InvaderShip.gunmount)
                        velocity = [System.Numerics.Vector2]::new(0, 0.1)
                        canvas   = $InvaderShip.blastDesign
                    }
    
                    break;
                }
        
        
                # Disregard other inputs
                Default {}
            }
        
        }

        onExitScreen  = {
            param($object, $didExitLeft, $didExitRigth, $didExitUp, $didExitDown)

            if ($object.ParentName -EQ 'InvaderShip_Blasts') {
                $object.isDead = $true
                $GameObjects['BlastExplosions'] += [PSCustomObject]@{
                    position         = [System.Numerics.Vector2]::new($object.position.x - 2, $object.position.y - 3)
                    ignoreCollisions = $true

                    lifetime         = 0
                    currentStage     = 5
                    stages           = @(
                        @(
                            ' #### ',
                            '######',
                            '# ## #',
                            '  ##  ',
                            '######'
                        ),
  
                        @(
                            ' #### ',
                            '######',
                            '  ##  ',
                            '  ##  ',
                            '######'
                        ),

                        @(
                            '  ##  ',
                            ' #### ',
                            '  ##  ',
                            '  ##  ', 
                            '######'
                        ),

                        @(
                            '      ',
                            '      ',
                            '  ##  ',
                            '  ##  ',
                            '######'),

                        @(
                            '      ', 
                            '      ',
                            '      ',
                            '  ##  ',
                            '######'
                        )    
                    )
           
                    canvas           = @(
                        '      ', 
                        '      ',
                        '      ',
                        '      ',
                        ' #### '
                    )  
                }
            }
        }

        # TODO
        onCollision   = {
            param($collider, $participants)
        }
    }


    # Start a generic gameloop with the configurations for this game.
    Start-GenericGameLoop @Configuration -TickIntervall 5

}