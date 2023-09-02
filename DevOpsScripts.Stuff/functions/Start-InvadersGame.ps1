

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

        GameObjects   = [ordered]@{

            InvaderShip        = [PSCustomObject]@{
                position    = [System.Numerics.Vector2]::new(10, 0)
                canvas      = $Customization.ship

                # custom parameters
                cooldown    = 0
                gunmount    = $Customization.gunmount
                blastDesign = $Customization.blast
            }

            CollidingTest      = [PSCustomObject]@{
                position   = [System.Numerics.Vector2]::new(10, 0)
                # alwaysDraw = $true
                canvas     = @(
                    'X'
                    'X'
                )
            }

            CollidingTest2     = [PSCustomObject]@{
                position   = [System.Numerics.Vector2]::new(13, 2)
                # alwaysDraw = $true
                canvas     = @(
                    '##'
                )
            }

            CollidingTest3     = [PSCustomObject]@{
                position   = [System.Numerics.Vector2]::new(22, 2)
                # alwaysDraw = $true
                canvas     = @(
                    '---'
                )
            }

            # Placeholder list for tracking all blasts.
            InvaderShip_Blasts = [PSCustomObject[]]@()
        }



        onEveryTickDo = {
            param($GameObects)

            # Update the gun cooldown of the spaceship.
            $GameObects['InvaderShip'].cooldown = [System.Math]::Max(0, $GameObects['InvaderShip'].cooldown - 1)
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



        # TODO
        onCollision   = {
            param()
        }
    }


    # Start a generic gameloop with the configurations for this game.
    Start-GenericGameLoop @Configuration

}