

<#
    .SYNOPSIS
    A function for creating fireworks in the Terminal.

    .DESCRIPTION
    A function for creating fireworks in the Terminal.
    Shoots fireworks in random intervalls. May not work correctly at times.
    Mainly just testing capabillities of Powershell Terminal.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS

                                                         *..*                
                                                        *_\/_*               
                  '.\'/.'                                *..* 
                  -= o =-
                  .'/.\'.                                                

                                    '
                                  = o =
                                    .
                                               .
                                               ^

                    .
                    ^

#>

function Start-Fireworks {

    [CmdletBinding( )]
    param (
        [Parameter(
            Position = 1,
            Mandatory = $false
        )]
        [ValidateRange(1, 1000)]
        [System.Int32]
        $TickIntervall = 5
    )

    # Inspired by: https://www.asciiart.eu/holiday-and-events/fireworks
    $fireworkExplosionTypes = @{
        type1 = @(
            @( 
                " '.\'/.' "
                ' -= o =- '
                " .'/.\'. "
            ),
            @(
                "   \'/   "
                ' -= o =- '
                "   /.\   "
            ),
            @(
                "    '    "
                ' -= o =- '
                "    .    "
            ),
            @(
                "    '    "
                '  = o =  '
                "    .    "
            ),
            @(
                "         "
                '    o    '
                "         "
            )
        )

        typ2  = @(
            @( 
                '  *::*  '
                '*__\/__*'
                '* ´/\` *'
                '  *::*  '
            ),
            @(
                '  *..*  '
                ' *_\/_* '
                ' * /\ * '
                '  *..*  '
            ),
            @(
                '  *..*  '
                ' *_\/_* '
                '  *..*  '
                '        ' 
            ),
            @(
                '   ..   '
                '  *\/*  '
                '   ..   '
                '        ' 
            ),
            @(
                '        '
                '   **   '
                '   \/   '
                '        ' 
            ),
            @(
                '        '
                '   **   '
                '        '
                '        ' 
            )
        )

        typ3  = @(
            @( 
                "   .   "
                ".'.:.'."
                "-=:o:=-"
                "'.':'.'"
                "   '   "
            ),
            @(
                "       "
                " '.:.' "
                "-=:o:=-"
                " .':'. "
                "       "
            ),
            @(
                "       "
                "  .:.  "
                "-=:o:=-"
                "  ':'  "
                "       "
            ),
            @(
                "       "
                "  . .  "
                "-=:o:=-"
                "  ' '  "
                "       "
            ),
            @(
                "       "
                "       "
                " =:o:= "
                "       "
                "       "
            ),
            @(
                "       "
                "       "
                "  :o:  "
                "       "
                "       "
            )
        )

        # More Fireworks 
        typ4  = @(
            @(
                ". \ | / ."
                "._. ! ._."
                " ._\!/_. "
                "  . ! .  "
                "    .    "
                "    .    "
            ),
            @(
                "  \ | / "
                "._. ! ._."
                " ._\!/_. "
                "  . ! .  "
                "    .    "
                "    .    "
            ),
            @(
                "    |    "
                " _. ! ._ "
                " ._\!/_. "
                "  . ! .  "
                "    .    "
                "    .    "
            ),
            @(
                "         "
                "  . ! .  "
                " ._\!/_. "
                "  . ! .  "
                "    .    "
                "    .    "
            ),
            @(
                "         "
                "  . ! .  "
                "  _\!/_  "
                "  . ! .  "
                "    .    "
                "    .    "
            ),
            @(
                "         "
                "         "
                "  _\!/_  "
                "  . ! .  "
                "    .    "
                "    .    "
            ),
            @(
                "         "
                "         "
                "    !    "
                "  . ! .  "
                "    .    "
                "    .    "
            ),
            @(
                "         "
                "         "
                "         "
                "  .   .  "
                "    .    "
                "    .    "
            ),
            @(
                "         "
                "         "
                "         "
                "         "
                "         "
                "    .    "
            )
        )
    }

    # The configurations for this game
    $Configuration = @{

        RequiredGameHeight = 15
        RequiredGameWidth  = 40

        # Objects get drawn in that order. Following objects will potentially hide previous objects.
        GameObjects        = [ordered]@{

            Fireworks            = [PSCustomObject[]]@(
                @{
                    position        = [System.Numerics.Vector2]::new(
                        50, 12
                    )
                    velocity        = [System.Numerics.Vector2]::new(0, -0.2)
                    canvas          = @(
                        '.',
                        '^'
                    )

                    explosionHeight = 7
                }
            )
            Fireworks_Explosions = [PSCustomObject[]]@()

            Fireworks_staticText = [PSCustomObject]@{
                position = [System.Numerics.Vector2]::new(1, 0)
                canvas   = @(
                    "Explosions:"
                )
            }
            Fireworks_count      = [PSCustomObject]@{
                position = [System.Numerics.Vector2]::new(13, 0)
                canvas   = @(
                    "00"
                )

                current  = 0
            }
            
        }



        onEveryTickDo      = {
            param($GameObects, $GameWidth, $GameHeight)

            if ((Get-Random -Minimum 0 -Maximum 50) -EQ 0) {
                
                $GameObects['Fireworks'] += [PSCustomObject]@{
                    position        = [System.Numerics.Vector2]::new(
                        (Get-Random -Minimum 10 -Maximum ($GameWidth - 10)), $GameHeight - 2
                    )
                    velocity        = [System.Numerics.Vector2]::new(0, -0.2)
                    canvas          = @(
                        '.',
                        '^'
                    )

                    explosionHeight = Get-Random -Minimum 4 -Maximum ($GameHeight - 7)
                }
            }

            if ($GameObects['Fireworks_count'].current -NE $GameObects['Fireworks_Explosions'].Count) {
                $GameObects['Fireworks_count'].redrawMark = $true
                $GameObects['Fireworks_count'].current = $GameObects['Fireworks_Explosions'].Count
                $GameObects['Fireworks_count'].canvas[0] = $($GameObects['Fireworks_Explosions'].Count)
            }

            foreach ($firework in $GameObects['Fireworks']) {
                if ([System.Math]::Round($firework.position.y) -LT $firework.explosionHeight) {
                    $firework.isDead = $true

                    $random = Get-Random -Minimum 0 -Maximum ($fireworkExplosionTypes.Values.Count)
                    $fireworkType = $fireworkExplosionTypes.Values | Select-Object -Skip $random -First 1
                    $GameObects['Fireworks_Explosions'] += [PSCustomObject]@{
                        position     = [System.Numerics.Vector2]::new(
                            ($firework.position.x - $fireworkType[0][0].Length / 2), $firework.position.y #+ $fireworkType.Count / 2
                        )

                        stageTime    = 0
                        maxStageTime = 20
                        currentStage = $fireworkType.Count - 1
                        stages       = $fireworkType
                        canvas       = $fireworkType | Select-Object -Last 1
                    }
                }
            }


            foreach ($explosion in $GameObects['Fireworks_Explosions']) {

                $explosion.stageTime += 1

                if ($explosion.stageTime -GT $explosion.maxStageTime) {
                    $explosion.stageTime = 0
                    $explosion.currentStage -= 1

                    if ($explosion.currentStage -LT 0) {
                        $explosion.isDead = $true
                    }
                    else {
                        $explosion.redrawMark = $true
                        $explosion.canvas = $explosion.stages[$explosion.currentStage]
                    }
                }

            }
        }

        onExitScreen       = {
            param($object, $GameObjects, $didExitLeft, $didExitRigth, $didExitUp, $didExitDown)

            if ($didExitUp -AND $object.ParentName -EQ 'Fireworks') {
                $object.isDead = $true
            }
        }
        
        onKeyEvent         = {
            param($KeyEvent, $GameObects)
        }

        onCollision        = {
            param($collider, $participants)
        }
    }


    # Start a generic gameloop with the configurations for this game.
    Start-GenericGameLoop @Configuration -TickIntervall $TickIntervall

}