

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

    Start a Loading-Bar for the duration of a Job:

    PS> $Job = Start-Job {
        # Lengthy Code simulated by Start-Sleep
        Start-Sleep -Seconds 10
    }

    PS> Start-LoadingBarAnimation $Job
#>

function Start-LoadingBarAnimation {

    param(
        [Parameter(
            Mandatory = $true
        )]
        [System.Management.Automation.Job]
        $Job,

        [Parameter(
            Mandatory = $false
        )]
        [System.Int32]
        $Length,

        [Parameter(
            Mandatory = $false
        )]
        [System.Int32]
        $Width = 3,

        [Parameter(
            Mandatory = $false
        )]
        [System.Int32]
        $OffsetX = 15,

        [Parameter(
            Mandatory = $false
        )]
        [System.Int32]
        $OffsetY = 2,

        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $DisplayText = 'Deploying...',


        [Parameter(
            Mandatory = $false
        )]
        [PSCustomObject]
        $DefaultParameters = @{

            segmentLength   = 3
            segmentDistance = 8
            segmentSteps    = 2
            character       = '#'
        }
    )

    $cumulatedOffset = 0
    Clear-Host

    while (
        $true -OR
        $Job.State -NE [System.Management.Automation.JobState]::Running -AND 
        $Job.State -NE [System.Management.Automation.JobState]::NotStarted
    ) {

        $character = $DefaultParameters.character
                
        $windowHeight = $host.UI.RawUI.WindowSize.Height
        $windowWidth = $host.UI.RawUI.WindowSize.Width

        if (!$PSBoundParameters.ContainsKey('Length')) {
            $Length = $windowWidth - 2 * $OffsetX
        }

        $segmentLength = $DefaultParameters.segmentLength
        $segmentDistance = $DefaultParameters.segmentDistance + $segmentLength
        $segmentSteps = $DefaultParameters.segmentSteps
        $segmentCount = [System.Math]::Floor($length / $segmentDistance)

        $positionX = $OffsetX
        $positionY = $OffsetY

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

}