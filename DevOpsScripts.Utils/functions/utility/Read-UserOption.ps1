

<#
    .SYNOPSIS
    Opens an interactive single line menue for user confirmation.

    .DESCRIPTION
    Opens an interactive single line menue for user confirmation.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS
    The selected option by the user.


    .EXAMPLE

    Present a simple prompt with two selections:

    Read-UserOption -Prompt "Confirm: "


    .EXAMPLE

    Present a simple prompt with two selections and an identation:

    Read-UserOption -Prompt "Confirm: " -i 5

#>


function Read-UserOption {

    param (
        # The input prompt to ask the user.
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $Prompt,

        # Indentation for the prompt to display.
        [Parameter(
            Mandatory = $false
        )]
        [System.int32]
        [Alias('i')]
        $Indendation = 0,
                
        # The Options to display for selection
        [Parameter(
            Mandatory = $false
        )]
        [System.String[]]
        $Options = $("Yes", "No"),

        # A Foregroundcolor for the text prompt.
        [Parameter()]
        [System.String]
        $TextHighlighting = "`e[37m",

        # Prevents jumping to the next line
        # When this method is called several times with these switch
        # The new call will overwrite the previous line
        [Parameter()]
        [switch]
        $NoNewLine
    )

    try {
        $prefix = ''
        if ($Indendation -GT 0) {
            $prefix = (0..$indendation | ForEach-Object { ' ' }) -join ''
        }
        $Prompt = $prefix + $Prompt.TrimEnd()

        $optionsSpacing = 2
        $optionsSpacing = (1..$optionsSpacing | ForEach-Object { ' ' }) -join ''

        $OptionsForeground = "`e[90m"
        $OptionsSelected = "`e[37m`e[45m"

        $selectedIndex = 0

        do {

            # Reset Cursor Position to start of Line for redrawing line.
            # Set the Cursor invisible to hide any movements.
            [System.Console]::CursorVisible = $false
            [System.Console]::SetCursorPosition(0, [System.Console]::GetCursorPosition().Item2)

            $emptyLine = (1..$($host.UI.RawUI.WindowSize.Width) | ForEach-Object { ' ' }) -join ''
            [System.Console]::Write($emptyLine)
            [System.Console]::SetCursorPosition(0, [System.Console]::GetCursorPosition().Item2)
            [System.Console]::Write($TextHighlighting)
            [System.Console]::write($Prompt)
            [System.Console]::Write("`e[0m")


            for ($index = 0; $index -LT $Options.Count; $index++) {

                [System.Console]::Write($optionsSpacing)
                if ($index -EQ $selectedIndex) {
                    [System.Console]::Write($OptionsSelected)
                    [System.Console]::Write($Options[$index])
                    [System.Console]::Write("`e[0m")
                }
                else {
                    [System.Console]::Write($OptionsForeground)
                    [System.Console]::Write($Options[$index])
                    [System.Console]::Write("`e[0m")
                }

            }
 
            # Process any Key Events by user.
            $keyEvent = [System.Console]::ReadKey($true)
            Switch ($keyEvent) { 

                { $_.Key -EQ [System.ConsoleKey]::RightArrow } {
                    $selectedIndex = ($selectedIndex + 1) % $Options.Count
                    break
                }

                { $_.Key -EQ [System.ConsoleKey]::LeftArrow } {
                    $selectedIndex = ($selectedIndex + $Options.Count - 1) % $Options.Count
                    break
                }

                { $_.Key -EQ [System.ConsoleKey]::Enter } {

                    return $Options[$selectedIndex]

                }

                # Disregard any other inputs.
                default {}

            }

        } while ($keyEvent.Key -ne [System.ConsoleKey]::Escape)
    }
    finally {
        # Make sure to always leave in any case function with a visible cursor again.
        [System.Console]::CursorVisible = $true
        
        if (!$NoNewLine) {
            Write-Host "" # Write a new Line to set the cursor to the next line.
        }
    }


}