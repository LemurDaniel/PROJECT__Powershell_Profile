

<#
    .SYNOPSIS
    Custom alternative for Read-Host with expanded capabilities.

    .DESCRIPTION
    Custom alternative for Read-Host with expanded capabilities.
    Cursor can be moved via LeftArrow and RightArrow in Userinput.
    Allows for removing character at cursor-position.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS
    Userinput if provided. If no userinput was provided the placeholder value will be returned,
    which may be an empty string or not.


    .EXAMPLE

    Read user input with a prompt:

    PS> Read-UserInput -Prompt "Enter a Value:" 

    .EXAMPLE

    Read user input with a prompt and a indentation:

    PS> Read-UserInput -Prompt "Enter a Value:" -i 5 

    .EXAMPLE

    Read user input with a prompt and a placeholder value:

    PS> Read-UserInput -Prompt "Enter a Value:" -Placeholder "default-bla-bla"

    .EXAMPLE

     Read user input with a prompt and a placeholder value as a SecureString:

    PS> Read-UserInput -Prompt "Enter a Value:" -Placeholder "default-bla-bla" -AsSecureString


    .EXAMPLE

    Read user input with a prompt and a placeholder value as a SecureString:

    PS> $readUserInputOptions = @{
            Prompt = "Enter a Tenant ID: "
            Matches = @{
                "^[{]?[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}[}]?$" = "Must be a valid GUID!"
            }
        }
        
    PS> Read-UserInput @readUserInputOptions

#>


function Read-UserInput {

    param (
        # The input prompt to ask the user.
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $Prompt,

        # An optional placeholder value, when no user input was entered.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Placeholder,

        # Indentation for the prompt to display.
        [Parameter(
            Mandatory = $false
        )]
        [System.int32]
        [Alias('i')]
        $Indendation = 0,

        # The maximum input length. Defaults to a high value.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Maximum = [System.Int32]::MaxValue,

        # The minimum input length. Defaults to 0.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Minimum = 0,

        # A map of regex-matches (keys) and error-messages (values).
        [Parameter(
            Mandatory = $false
        )]
        [System.Collections.Hashtable]
        $Matches = @{},


        # A passwordlike field returning a secure string.
        [Parameter()]
        [switch]
        $AsSecureString,


        # A Foregroundcolor for the text prompt.
        [Parameter()]
        [System.ConsoleColor]
        $Foregroundcolor = [System.ConsoleColor]::White,


        # Only return user input, also if empty. Disregard placeholder.
        [Parameter()]
        [switch]
        $OnlyUserinput,

        # Marks this input as required. Similar to setting minimum above 0, but with different Error-Display.
        [Parameter()]
        [switch]
        $Required
    )

    $prefix = ''
    if ($Indendation -GT 0) {
        $prefix = (0..$indendation | ForEach-Object { ' ' }) -join ''
    }
    $Prompt = $prefix + $Prompt.TrimEnd() + " "

    $Placeholder = $Placeholder.Trim()
    $ErrorMessage = ""
    $UserInput = ""
    $CursorOffset = 0 # Offset cursor from left to right
    
    try {
        do {

            # Reset Cursor Position to start of Line for redrawing line.
            # Set the Cursor invisible to hide any movements.
            [System.Console]::CursorVisible = $false
            [System.Console]::SetCursorPosition(0, [System.Console]::GetCursorPosition().Item2)

            # Overwrite line with empty string reset cursor again and the draw actual prompt.
            $whitespaces = (0..($host.UI.RawUI.WindowSize.Width - 1) | ForEach-Object { " " }) -join ""
            Write-Host -NoNewline $whitespaces

            [System.Console]::SetCursorPosition(0, [System.Console]::GetCursorPosition().Item2)
            Write-Host -ForegroundColor $Foregroundcolor  -NoNewline $Prompt


            if ([System.String]::IsNullOrEmpty($UserInput)) {
                # Write Placeholder text as greyish to inidcate placeholder text.
                Write-Host -ForegroundColor Black -NoNewline $Placeholder

                # Set the Cursor on wihtespace before placeholder text, so user can overwrite placeholder.
                [System.Console]::SetCursorPosition(
                    [System.Console]::GetCursorPosition().Item1 - $Placeholder.Length - 1,
                    [System.Console]::GetCursorPosition().Item2
                )
            }

            # If the userinput is not empty, draw the user input instead of placeholder.
            else {
                $drawnUserInput = $UserInput

                if ($AsSecureString) {
                    # Draw userinput as stars.
                    $drawnUserInput = (0..($UserInput.Length - 1) | ForEach-Object { "*" }) -join ''
                }
                   
                # Draw Userinput and set cursorposition at the end of drawn line.
                Write-Host -ForegroundColor White -NoNewline $drawnUserInput
                [System.Console]::SetCursorPosition(
                    $Prompt.Length + $CursorOffset, # Use cursoroffset
                    [System.Console]::GetCursorPosition().Item2
                )
            }

            if ($ErrorMessage) {
                Write-Host -ForegroundColor Red -NoNewline " $ErrorMessage"
            }

            # That the Cursor visible again as user input is now expected.
            [System.Console]::CursorVisible = $true
 
            # Process any Key Events by user.
            $keyEvent = [System.Console]::ReadKey($true)
            Switch ($keyEvent) { 

                { $_.Key -EQ [System.ConsoleKey]::Escape } {
                    throw "Operation was Cancelled due to pressing '$($_.Key)'"
                }

                { $_.Key -EQ [System.ConsoleKey]::Backspace } {

                    if ($ErrorMessage) {
                        # If an error message is displayed, clear the message.
                        $ErrorMessage = $null
                        break
                    }

                    if ($CursorOffset -EQ 0) {
                        break # Ignore backspace when Cursor position is at start of userinput.
                    }

                    if ($CursorOffset -EQ $UserInput.Length) {
                        # Remove from the End of the string.
                        $UserInput = $UserInput.Substring(0, [System.Math]::Max(0, $UserInput.Length - 1))
                    }
                    else {
                        # Remove in the middle of string, when cursor-position is not at the end.
                        $UserInput = $UserInput.Substring(0, $CursorOffset - 1) + $UserInput.Substring($CursorOffset)
                    }


                    $CursorOffset -= 1
                    break
                }

                { $_.Key -EQ [System.ConsoleKey]::RightArrow } {
                    $CursorOffset = [System.Math]::Min($UserInput.Length, $CursorOffset + 1)
                    $ErrorMessage = $null
                    break
                }

                { $_.Key -EQ [System.ConsoleKey]::LeftArrow } {
                    $CursorOffset = [System.Math]::Max(0, $CursorOffset - 1)
                    $ErrorMessage = $null
                    break
                }

                # Anything thats an actual character
                { ![System.Char]::IsControl($_.KeyChar) } {

                    if ($UserInput.Length -EQ $Maximum) {
                        $ErrorMessage = "Maximaly '$Maximum'-Characters allowed!"
                        break # Ignore when max-length is reached
                    }

                    if ($CursorOffset -EQ $UserInput.Length) {
                        # Insert chars at the end of the string when cursor is at end of string.
                        $UserInput += $_.KeyChar
                    }
                    else {
            
                        # Insert chars in the middle of string, according to cursor position.
                        $UserInput = $UserInput.Substring(0, $CursorOffset) + $_.KeyChar + $UserInput.Substring($CursorOffset) 
                    }

                    $CursorOffset += 1
                    $ErrorMessage = $null
                    break
                }


                { $_.Key -EQ [System.ConsoleKey]::Enter } {

                    $returnValue = [System.String]::IsNullOrEmpty($UserInput) -AND !$OnlyUserinput ? $Placeholder : $UserInput

                    foreach ($match in $Matches.GetEnumerator()) {
                        if (![regex]::Match($returnValue, $match.Name).Success) {
                            $ErrorMessage = $match.Value
                        }
                    }


                    if ([System.String]::isNullOrEmpty($ErrorMessage)) {
                        if ($Required -AND [System.String]::isNullOrEmpty($returnValue)) {
                            $ErrorMessage = "Input is required"
                            break
                        }

                        elseif ($returnValue.Length -LT $Minimum) {
                            $ErrorMessage = "At least '$Minimum'-Characters required!"
                        }

                        elseif ($returnValue.Length -GT $Maximum) {
                            $ErrorMessage = "Maximaly '$Maximum'-Characters allowed!"
                        }

                        else {
                            # Return value from Method if everything is correct
                            return $AsSecureString -AND $returnValue.length -GT 0 ? ($returnValue | ConvertTo-SecureString -AsPlainText) : $returnValue
                        }
                    }

                    break
                }

                # Disregard any other inputs.
                default {}

            }

        } while ($keyEvent.Key -ne [System.ConsoleKey]::Escape)
    }
    finally {
        # Make sure to always leave in any case function with a visible cursor again.
        [System.Console]::CursorVisible = $true
        Write-Host "" # Write a new line
    }


}