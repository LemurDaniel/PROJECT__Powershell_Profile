


<#
    .SYNOPSIS
    Write a Menue to the Console with interactive selection.

    .DESCRIPTION
    Write a Menue to the Console with interactive selection.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Selected Item.


    .EXAMPLE

    Select a File to open in the Current Path:
    
    PS> $selectedItem = Select-ConsoleMenu -Options (Get-ChildItem -File) -Property Name
    PS> Start-Process $selectedItem


    .LINK
        
#>

Function Select-ConsoleMenu {

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true
        )]
        [System.Object[]]
        $Options,

        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Property,

        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Description = 'Please Choose from the Menu:'
    )

    if ($PSBoundParameters.ContainsKey('Property')) {
        $SelectionOptions = $Options | Select-Object -ExpandProperty $Property
    }
    else {
        $SelectionOptions = $Options
    }


    $prefixSelected = ' => '
    $prefixNonSelected = ' '
    $selectionIndex = 0

    try {

        do {
            [System.Console]::Clear()
            [System.Console]::CursorVisible = $false
            [System.Console]::CursorTop = 0
          
            # Show Selection
            Write-Host -ForegroundColor Magenta ("**$($description.trim())**" | ConvertFrom-Markdown -AsVT100EncodedString).VT100EncodedString

            $SelectionOptions | ForEach-Object { $index = 0 } {

                if ($index -eq $selectionIndex) {
                    Write-Host "$prefixSelected" -NoNewline
                    Write-Host -BackgroundColor Magenta $_
                } 
                else {
                    Write-Host "$prefixNonSelected" -NoNewline
                    Write-Host $_
                }

                $index++

            }
    
            # Process and switch key presses
            $keyDownEvent = [System.Console]::ReadKey($true)
            Switch ($keyDownEvent.Key) {
    
                { $_ -eq [System.ConsoleKey]::Enter } {
                    return $Options[$selectionIndex]
                }

                { $_ -eq [System.ConsoleKey]::Escape } {
                    throw "Operation was Cancelled due to Input $($keyDownEvent.Key)"
                }

                { $_ -in @([System.ConsoleKey]::W, [System.ConsoleKey]::UpArrow) } {
                    $selectionIndex = ($selectionIndex + $SelectionOptions.Length - 1) % $SelectionOptions.Length
                }
    
                { $_ -in @([System.ConsoleKey]::S, [System.ConsoleKey]::DownArrow) } {
                    $selectionIndex = ($selectionIndex + $SelectionOptions.Length + 1) % $SelectionOptions.Length
                }

                default {
                    $hint = ('**Use on of the Following Keys: (ArrowUP | ArrowDown | W | S | Enter)**' | ConvertFrom-Markdown -AsVT100EncodedString).VT100EncodedString
                    Write-Host 
                    Write-Host -ForegroundColor Magenta -Separator ' ' $hint, '... '
                    $null = [System.Console]::ReadKey($true)
                }

            }

      
        } while ($keyDownEvent.Key -ne [System.ConsoleKey]::Enter)

    }
    finally {
        [System.Console]::CursorVisible = $true
    } 
}
