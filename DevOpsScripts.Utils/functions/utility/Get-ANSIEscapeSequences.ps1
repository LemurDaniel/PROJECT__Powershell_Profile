


<#
    .SYNOPSIS
    Creates an ANSI-Escape Sequences for customizing Terminal-Output.

    .DESCRIPTION
    Creates an ANSI-Escape Sequences for customizing Terminal-Output.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS

    .EXAMPLE

    Get ANSI-Sequences as Hashtable:

    PS> $ANSI = Get-ANSIEscapeSequences -AsHashtable

    .EXAMPLE

    Get ANSI-Sequences as Object:

    PS> $ANSI = Get-ANSIEscapeSequences -AsObject

#>


function Get-ANSIEscapeSequences {

    param(
        [Parameter(
            ParameterSetName = "object"
        )]
        [switch]
        $AsObject,

        [Parameter(
            ParameterSetName = "hashtable"
        )]
        [switch]
        $AsHashtable
    )

    <#
    
    NOTE:
    https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797#rgb-colors
        
    #>

    $Sequences = @{

        general      = @{
            BELL      = "`a" # This makes a sound.
            BACKSPACE = "`b"
            LINE_FEED = "`n"
            FORM_FEED = "`f"
            CARRIAGE  = "`r"
            TAB       = @{
                VERTICAL   = "`v"
                HORIZONTAL = "`t"
            }
        }
    
        cursor       = @{
            HOME      = "`e[H" # Move cursor to home position.
            POSITION  = "`e[{line};{column}" # Move cursor to position.
            UP        = "`e[{num}A" # Move cursor up by amount.
            DOWN      = "`e[{num}B" # Move cursor down by amount.
            RIGHT     = "`e[{num}C" # Move cursor right by amount.
            LEFT      = "`e[{num}D" # Move cursor left by amount.
            NEXT_LINE = "`e[{num}E" # Move cursor to start of next line.
            PREV_LINE = "`e[{num}F" # Move cursor to start of previous line.
            COLUMN    = "`e[{num}G" # Move cursor to column in current line.
            RESET     = "`e[6n" # Reset cursor position.
            SAVE      = "`e[s"  # Save cursor position.
            RESTORE   = "`e[u" # Restore cursor position.
        }
    
        erase        = @{
            IN_DISPLAY             = "`e[J" # Erase in display.
            CURSOR_TO_SCREEN_END   = "`e[0J" # Erase from cursor until end of screen.
            CURSOR_TO_SCREEN_START = "`e[1J" # Erase from cursor to beginning of screen.
            ENITRE_SCREEN          = "`e[2J" # Erase entire screen.
            SAVED_LINES            = "`e[3J" # Erase saved lines.
            IN_LINE                = "`e[K" # Erase in line.
            CURSOR_TO_LINE_END     = "`e[0K" # Erase from cursor to end of line.
            CURSOR_TO_LINE_START   = "`e[1K" # Erase from cursor to start of line.
            ENTIRE_LINE            = "`e[2K" # Erase line
        }
    
        graphics     = @{
            RESET_ALL     = "`e[0m"
            BOLD          = @{
                SET   = "`e[1m"
                RESET = "`e[22m"
            }
            DIM           = @{
                SET   = "`e[2m"
                RESET = "`e[22m"
            }
            ITALIC        = @{
                SET   = "`e[3m"
                RESET = "`e[23m"
            }
            UNDERLINE     = @{
                SET   = "`e[4m"
                RESET = "`e[24m"
            }
            BLINKING      = @{
                SET   = "`e[5m"
                RESET = "`e[25m"
            }
            INVERSE       = @{
                SET   = "`e[7m"
                RESET = "`e[27m"
            }
            HIDDEN        = @{
                SET   = "`e[8m"
                RESET = "`e[28m"
            }
            STRIKETHROUGH = @{
                SET   = "`e[9m"
                RESET = "`e[29m"
            }
        }
    
        COLORS_8BIT  = @{
            FOREGROUND = "`e[38;5;{ID}m"
            BACKGROUND = "`e[48;5;{ID}m"
        }
    
        COLORS_24BIT = @{
            FOREGROUND = "`e[38;2;{R};{G};{B}m"
            BACKGROUND = "`e[48;2;{R};{G};{B}m"
        }
    }


    if ($AsHashtable) {
        return $Sequences
    }
    elseif ($AsObject) {
        return $Sequences | ConvertTo-Json | ConvertFrom-Json
    }

}
