


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

    $SelectionOptions = $Options | ForEach-Object {
        return @{
            name        = $PSBoundParameters.ContainsKey('Property') ? ($_."$Property") : $_
            returnValue = $_
        }
    }

    $reservedLines = 8
    $initialSelectionSize = $Host.UI.RawUI.WindowSize.Height
    $selectionIndexOnPage = 0
    $currentPage = 0

    $searchString = ''

    $prefixSelected = ' => '
    $prefixNonSelected = '    '

    try {

        do {
            [System.Console]::CursorTop = 0
            [System.Console]::CursorVisible = $false
            [System.Console]::Clear()
          
            Write-Host -ForegroundColor Magenta ("**$($Description.trim())**" | ConvertFrom-Markdown -AsVT100EncodedString).VT100EncodedString

            # Filter Options !!! Wrap in Array to make sure to still have an array, when only one element remains. !!!
            $filteredOptions = @($SelectionOptions | Where-Object { $_.name.toLower() -Like "*$($searchString.ToLower())*" })

            # Do page and selection calculations.
            $maxSelectionsPerPage = $initialSelectionSize - $reservedLines
            $totalCountOfPages = [System.Math]::Ceiling($filteredOptions.Count / $maxSelectionsPerPage)
            $lastPageMaxIndex = $filteredOptions.Count % $maxSelectionsPerPage - 1

            # Fix if current Page if out-of-range.
            $currentPage = $currentPage -GE $totalCountOfPages ? $totalCountOfPages - 1 : $currentPage

            # Caluclation for current Page
            $isLastPage = $currentPage -EQ ($totalCountOfPages - 1)
            $selectionPageOffset = $currentPage * $maxSelectionsPerPage
            $selectionIndexOnPage = $selectionIndexOnPage -GT $lastPageMaxIndex -AND $isLastPage ? $lastPageMaxIndex : $selectionIndexOnPage

            $filteredOptions | `
                Select-Object -Skip $selectionPageOffset | `
                Select-Object -First $maxSelectionsPerPage | `
                ForEach-Object { $index = 0 } {

                if ($index -eq $selectionIndexOnPage) {
                    Write-Host "$prefixSelected" -NoNewline
                    Write-Host $_.Name -BackgroundColor Magenta
                } 
                else {

                    $startIndex = $_.Name.toLower().IndexOf($searchString.toLower())
                    $firstPart = $_.Name.Substring(0, $startIndex)
                    $highlightedPart = $_.Name.Substring($startIndex, $searchString.Length)
                    $lastPart = $_.Name.Substring($startIndex + $searchString.Length)

                    Write-Host "$prefixNonSelected" -NoNewline
                    Write-Host -NoNewline $firstPart
                    Write-Host -NoNewline $highlightedPart -BackgroundColor Cyan
                    Write-Host -NoNewline $lastPart 
                    Write-Host
                }

                $index++

            }

            if ($totalCountOfPages -gt 0) {
                Write-Host
                #Write-Host -NoNewline "Page " 
                Write-Host -NoNewline -BackgroundColor white "$($currentPage+1)/$totalCountOfPages"
            }
    
            if ($searchString.Length -gt 0) {
                Write-Host -NoNewline '     Searching For: '
                Write-Host -NoNewline -BackgroundColor Cyan "'$SearchString'"
            }
                            
            Write-Host

            # Process and switch key presses
            $keyDownEvent = [System.Console]::ReadKey($true)
            Switch ($keyDownEvent) {
    
                { $_.Key -eq [System.ConsoleKey]::Enter } {
                    return $filteredOptions[$selectionIndexOnPage].returnValue
                }

                { $_.Key -EQ [System.ConsoleKey]::Escape } {
                    throw "Operation was Cancelled due to Input $($keyDownEvent.Key)"
                }

                { $_.Key -EQ [System.ConsoleKey]::UpArrow } {
                    $selectionIndexOnPage = $selectionIndexOnPage - 1
                    if ($selectionIndexOnPage -LT 0) {
                        $currentPage = ($currentPage + $totalCountOfPages - 1) % $totalCountOfPages
                        $selectionIndexOnPage = $maxSelectionsPerPage - 1
                    }
                    break
                }
    
                { $_.Key -EQ [System.ConsoleKey]::DownArrow } {
                    $selectionIndexOnPage = $selectionIndexOnPage + 1
                    if ($selectionIndexOnPage -GT $maxSelectionsPerPage - 1 -OR ($selectionIndexOnPage -GT $lastPageMaxIndex -AND $isLastPage)) {
                        $currentPage = ($currentPage + $totalCountOfPages + 1) % $totalCountOfPages
                        $selectionIndexOnPage = 0
                    }
                    break
                }

                { $_.Key -EQ [System.ConsoleKey]::LeftArrow } {
                    $currentPage = ($currentPage + $totalCountOfPages - 1) % $totalCountOfPages
                    break
                }

                { $_.Key -EQ [System.ConsoleKey]::RightArrow } {
                    $currentPage = ($currentPage + $totalCountOfPages + 1) % $totalCountOfPages
                    break
                }
    
                { $_.Key -EQ [System.ConsoleKey]::Backspace } {
                    $searchString = $searchString.Substring(0, [System.Math]::Max(0, $searchString.Length - 1))
                    break
                }

                { $null -ne $_.KeyChar } {
                    $temporarySearchString = $searchString + $_.KeyChar
                    $remaining = $SelectionOptions | Where-Object { $_.name.toLower() -Like "*$($temporarySearchString.ToLower())*" }
                    $searchString = $remaining.Length -gt 0 ? $temporarySearchString  : $searchString
                    break
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
