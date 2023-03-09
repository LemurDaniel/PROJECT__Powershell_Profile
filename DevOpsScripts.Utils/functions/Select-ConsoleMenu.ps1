


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

    $selectionIndexOnPage = 0
    $maxSelectionsPerPage = 10
    $countOfPages = [System.Math]::Ceiling($Options.Count / 10)
    $currentPage = 0

    $prefixSelected = ' => '
    $prefixNonSelected = '    '

    try {

        do {
            [System.Console]::CursorTop = 0
            [System.Console]::CursorVisible = $false
            [System.Console]::Clear()
          
            Write-Host -ForegroundColor Magenta ("**$($Description.trim())**" | ConvertFrom-Markdown -AsVT100EncodedString).VT100EncodedString


            $maxSelectionCurrentPage = $maxSelectionsPerPage
            $selectionPageOffset = $currentPage * $maxSelectionsPerPage
            $selectionIndex = [System.Math]::Min($maxSelectionCurrentPag, $selectionIndexOnPage + $selectionPageOffset)

            $SelectionOptions | `
                Select-Object -Skip $selectionPageOffset | `
                Select-Object -First $maxSelectionsPerPage | `
                ForEach-Object { $index = 0 } {

                if ($index -eq $selectionIndexOnPage) {
                    Write-Host "$prefixSelected" -NoNewline
                    Write-Host -BackgroundColor Magenta $_
                } 
                else {
                    Write-Host "$prefixNonSelected" -NoNewline
                    Write-Host $_
                }

                $index++

            }

            if ($countOfPages -gt 0) {
                Write-Host
                #Write-Host -NoNewline "Page " 
                Write-Host -NoNewline -BackgroundColor white "$($currentPage+1)/$countOfPages"
                Write-Host
            }
    
            # Process and switch key presses
            $keyDownEvent = [System.Console]::ReadKey($true)
            Switch ($keyDownEvent.Key) {
    
                { $_ -eq [System.ConsoleKey]::Enter } {
                    return $Options[$selectionIndexOnPage + $selectionPageOffset]
                }

                { $_ -eq [System.ConsoleKey]::Escape } {
                    throw "Operation was Cancelled due to Input $($keyDownEvent.Key)"
                }

                { $_ -in @([System.ConsoleKey]::W, [System.ConsoleKey]::UpArrow) } {
                    $selectionIndexOnPage = ($selectionIndexOnPage + $maxSelectionCurrentPage - 1) % $maxSelectionCurrentPage
                }
    
                { $_ -in @([System.ConsoleKey]::S, [System.ConsoleKey]::DownArrow) } {
                    $selectionIndexOnPage = ($selectionIndexOnPage + $maxSelectionCurrentPage + 1) % $maxSelectionCurrentPage
                }

                { $_ -in @([System.ConsoleKey]::A, [System.ConsoleKey]::LeftArrow) } {
                    $currentPage = ($currentPage + $countOfPages - 1) % $countOfPages
                }
    
                { $_ -in @([System.ConsoleKey]::D, [System.ConsoleKey]::RightArrow) } {
                    $currentPage = ($currentPage + $countOfPages + 1) % $countOfPages
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
