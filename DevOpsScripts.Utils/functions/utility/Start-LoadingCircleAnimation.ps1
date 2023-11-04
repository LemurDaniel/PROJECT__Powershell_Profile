

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

    PS> Start-LoadingAnimation $Job
#>

function Start-LoadingCircleAnimation {

    param(
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
            displayText = 'Deploying...'
            character   = '##'
            radius      = 3
            steps       = 16
        }
    )

    $offsetAngle = 0
    $positions = @()
    Clear-Host

    while (
        $true -OR
        $Job.State -EQ [System.Management.Automation.JobState]::Running -OR 
        $Job.State -EQ [System.Management.Automation.JobState]::NotStarted
    ) {


        $positions = @()
        $steps = $DefaultParameters.steps
        $radius = $DefaultParameters.radius
        $character = $DefaultParameters.character
        $displayText = $DefaultParameters.displayText

        $windowHeight = $host.UI.RawUI.WindowSize.Height
        $windowWidth = $host.UI.RawUI.WindowSize.Width - ($host.UI.RawUI.WindowSize.Width / 8)
        $offsetWindowY = [System.Math]::Round($windowHeight / 2 - $DefaultParameters.Circle.Radius / 2) - 4
        
        # Some information because TAU isn't as common as PI
        # I like to use TAU as a shortand for 2*PI, but still love PI nonetheless.
        # Some additional resources:
        # - https://de.wikipedia.org/wiki/Kreiszahl#Alternative_Kreiszahl_τ
        # - https://en.wikipedia.org/wiki/Tau#Mathematics
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
}