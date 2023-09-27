

<#
    .SYNOPSIS
    Creats a Loading-Animation for the duration of a Background-Job.
    This is still just prototyping.

    .DESCRIPTION
    Creats a Loading-Animation for the duration of a Background-Job.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS


    .EXAMPLE

    Start a Loading-Circle for the duration of a Job:

    PS> $Job = Start-Job {
        # Lengthy Code simulated by Start-Sleep
        Start-Sleep -Seconds 10
    }

    PS> Start-LoadingAnimation Circle $Job

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
        }
    )

    $offsetAngle = 0
    $positions = @()
    while ($true) {

        switch ($kind) {
            
            "Circle" { 

                $positions = @()
                $steps = $DefaultParameters.Circle.steps
                $radius = $DefaultParameters.Circle.radius
                $character = $DefaultParameters.Circle.character
                $displayText = $DefaultParameters.Circle.displayText

                $windowHeight = $host.UI.RawUI.WindowSize.Height
                $windowWidth = $host.UI.RawUI.WindowSize.Width - ( $host.UI.RawUI.WindowSize.Width / 8)
                $offsetWindowY = [System.Math]::Round($windowHeight / 2 - $DefaultParameters.Circle.Radius / 2) - 4
        
                $offsetAngle += [System.Math]::TAU / $steps
                for ($angle = [System.Math]::TAU / $steps * 2; $angle -LT [System.Math]::TAU; $angle += [System.Math]::TAU / $steps) {
        
                    $positionX = [System.Math]::Round([System.Math]::Cos($angle + $offsetAngle) * $Radius * 2)
                    $positionY = [System.Math]::Round([System.Math]::Sin($angle + $offsetAngle) * $Radius )
        
                    $positionY = $positionY + ($positionY -GT 0 ? 0 : 0) 
        
                    $cursorPositionY = [System.Math]::Round($windowHeight / 2) + $positionY - $offsetWindowY
                    $cursorPositionX = [System.Math]::Round($windowWidth / 2) + $positionX
        
                    [System.Console]::SetCursorPosition($cursorPositionX, $cursorPositionY)
                    Write-Host -ForegroundColor Green -NoNewline $character

                    $positions += [System.Numerics.Vector2]::new($cursorPositionX, $cursorPositionY)
                }
        
                [System.Console]::CursorVisible = $false
                [System.Console]::SetCursorPosition(
                    $windowWidth / 2 - [System.Math]::Ceiling($displayText.length / 2) + 1, 
                    [System.Math]::Round($windowHeight / 2) - $offsetWindowY
                )
                Write-Host -ForegroundColor Green -NoNewline $displayText

                Start-Sleep -MilliSeconds 200
                
                [System.Console]::SetCursorPosition(
                    $windowWidth / 2 - [System.Math]::Ceiling($displayText.length / 2) + 1, 
                    [System.Math]::Round($windowHeight / 2) - $offsetWindowY
                )
                Write-Host -ForegroundColor Green -NoNewline ($displayText -replace '.', ' ')

                foreach ($pos in $positions) {
                    [System.Console]::SetCursorPosition($pos.x, $pos.y)
                    $cleanup = $character -replace '.', ' '
                    Write-Host -NoNewline $cleanup
                }
                
            }

            "Bar" { 

            }

            Default {
                Throw "Not supported!"
            }
        }

        if ($Job.State -NE [System.Management.Automation.JobState]::Running) {
            return
        }
    }
}