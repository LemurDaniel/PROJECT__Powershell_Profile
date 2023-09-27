

<#
    .SYNOPSIS
    Creats a Loading-Animation for the duration of a Background-Job.
    This is still just prototyping.

    .DESCRIPTION
    Creats a Loading-Animation for the duration of a Background-Job.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS

    A loading animation:

    ##################################################
    #     ####          ####        ####        #### #
    #     ####         Deploying... ####        #### #
    #     ####          ####        ####        #### #
    ##################################################

    .EXAMPLE

    Start a Loading-Circle for the duration of a Job:

    PS> $Job = Start-Job {
        # Lengthy Code simulated by Start-Sleep
        Start-Sleep -Seconds 10
    }

    PS> Start-LoadingAnimation Circle $Job

    .EXAMPLE

    Start a Loading-Bar for the duration of a Job:

    PS> $Job = Start-Job {
        # Lengthy Code simulated by Start-Sleep
        Start-Sleep -Seconds 10
    }

    PS> Start-LoadingAnimation Bar $Job
#>

function Start-LoadingAnimation {

    param(
        [Parameter(
            Mandatory = $true
        )]
        [ValidateSet('Circle', 'Bar')]
        $Kind,

        [Parameter(
            Mandatory = $true
        )]
        [System.Management.Automation.Job]
        $Job,

        [Parameter(
            Mandatory = $false
        )]
        [PSCustomObject]
        $DefaultParameters = @{
            Circle = @{
                displayText = 'Deploying...'
                character   = '##'
                radius      = 3
                steps       = 16
            }
            Bar    = @{
                length          = 50
                width           = 3
                offsetX         = 2
                offsetY         = 2
                segmentLength   = 3
                segmentDistance = 9
                segmentSteps    = 2
                character       = '#'
                displayText     = 'Deploying...'
            }
        }
    )

    $offsetAngle = 0
    $cumulatedOffset = 0
    $positions = @()
    Clear-Host

    while ($true) {

        switch ($kind) {

            "Circle" { 

                $positions = @()
                $steps = $DefaultParameters.Circle.steps
                $radius = $DefaultParameters.Circle.radius
                $character = $DefaultParameters.Circle.character
                $displayText = $DefaultParameters.Circle.displayText

                $windowHeight = $host.UI.RawUI.WindowSize.Height
                $windowWidth = $host.UI.RawUI.WindowSize.Width - ($host.UI.RawUI.WindowSize.Width / 8)
                $offsetWindowY = [System.Math]::Round($windowHeight / 2 - $DefaultParameters.Circle.Radius / 2) - 4
        
                $offsetAngle += [System.Math]::TAU / $steps
                for ($angle = [System.Math]::TAU / $steps * 2; $angle -LT [System.Math]::TAU; $angle += [System.Math]::TAU / $steps) {
        
                    $positionX = [System.Math]::Round([System.Math]::Cos($angle + $offsetAngle) * $Radius * 2)
                    $positionY = [System.Math]::Round([System.Math]::Sin($angle + $offsetAngle) * $Radius )
        
                    $cursorPositionY = [System.Math]::Round($windowHeight / 2) + $positionY - $offsetWindowY
                    $cursorPositionX = [System.Math]::Round($windowWidth / 2) + $positionX
        
                    [System.Console]::SetCursorPosition($cursorPositionX, $cursorPositionY)
                    [System.Console]::Write($character)

                    $positions += [System.Numerics.Vector2]::new($cursorPositionX, $cursorPositionY)
                }
        
                [System.Console]::CursorVisible = $false
                [System.Console]::SetCursorPosition(
                    $windowWidth / 2 - [System.Math]::Ceiling($displayText.length / 2) + 1, 
                    [System.Math]::Round($windowHeight / 2) - $offsetWindowY
                )
                [System.Console]::Write($displayText)

                Start-Sleep -MilliSeconds 200

                foreach ($pos in $positions) {
                    [System.Console]::SetCursorPosition($pos.x, $pos.y)
                    $cleanup = $character -replace '.', ' '
                    [System.Console]::Write($cleanup)
                }
                
                [System.Console]::SetCursorPosition(
                    $windowWidth / 2 - [System.Math]::Ceiling($displayText.length / 2) + 1, 
                    [System.Math]::Round($windowHeight / 2) - $offsetWindowY
                )
                [System.Console]::Write($displayText -replace '.', ' ')
                
            }

            "Bar" { 

                # And more distractions from lonley life
                $length = $DefaultParameters.Bar.Length
                $width = $DefaultParameters.Bar.width
                $character = $DefaultParameters.Bar.character
                $displayText = $DefaultParameters.Bar.displayText
                
                $windowHeight = $host.UI.RawUI.WindowSize.Height
                $windowWidth = $host.UI.RawUI.WindowSize.Width - ($host.UI.RawUI.WindowSize.Width / 8)

                $segmentLength = $DefaultParameters.Bar.segmentLength
                $segmentDistance = $DefaultParameters.Bar.segmentDistance + $segmentLength
                $segmentSteps = $DefaultParameters.Bar.segmentSteps
                $segmentCount = [System.Math]::Floor($length / $segmentDistance)

                $positionX = $DefaultParameters.Bar.offsetX
                $positionY = $DefaultParameters.Bar.offsetY

                $lineUpperLower = (1..$length | ForEach-Object { $character }) -Join ''

                [System.Console]::SetCursorPosition($positionX, $positionY)
                [System.Console]::Write($lineUpperLower)
                [System.Console]::SetCursorPosition($positionX, $positionY + $width + 1)
                [System.Console]::Write($lineUpperLower)

                1..$width | ForEach-Object {
                    $line = $character + $lineUpperLower.Substring(2, $lineUpperLower.Length - 2).replace($character, ' ') + $character
                    [System.Console]::SetCursorPosition($positionX, $positionY + $_)
                    [System.Console]::Write($line)
                }

                $segmentLine = (0..$segmentLength | ForEach-Object { $character }) -Join ''
                for ($count = 0; $count -LT $segmentCount; $count++) {

                    $calculatedOffset = ($segmentDistance * $count + $cumulatedOffset) % $length

                    1..$width | ForEach-Object {
                        [System.Console]::SetCursorPosition($positionX + $calculatedOffset, $positionY + $_)
                        $drawnLine = $segmentLine
                        if ($length - $calculatedOffset -LT $segmentLength) {
                            $drawnLine = $segmentLine.Substring(0, $length - $calculatedOffset)
                        }
                        [System.Console]::Write($drawnLine)
                    }
                }

                [System.Console]::SetCursorPosition(
                    $positionX + $length / 2 - ($displayText.Length / 2),
                    $positionY + $width / 2
                )
                [System.Console]::Write($displayText)
                [System.Console]::CursorVisible = $false
                $cumulatedOffset = ($cumulatedOffset + $segmentSteps) % $length 

                Start-Sleep -Milliseconds 200
            }

            Default {
                Throw "Not supported!"
            }
        }


        if ($Job.State -NE [System.Management.Automation.JobState]::Running -AND $Job.State -NE [System.Management.Automation.JobState]::NotStarted) {
            return
        }
    }
}