


<#
    .SYNOPSIS
    Write a Menue to the Console with interactive selection.

    .DESCRIPTION
    Write a Menue to the Console with interactive selection.

    Supports several Pages.
        => Switchable via Left- and Right-Keyboard Keys.

    Chosen Element is Highlighted.
        => Switchable via Up- and Down-Keyboard Keys.

    Wirting a Text highlights every entry with the specifed text.
        => Pressing Backspace will remove the last letter from the text.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The Selected Item.


    .EXAMPLE

    Select a File to open in the Current Path:
    
    PS> Start-Process -FilePath (Select-ConsoleMenu -Options (Get-ChildItem -File) -Property Name)


    .LINK
        
#>

# TODO rewrite with [System.Console]::SetCursorPosition to prevent flickers from redrawing whole menue.
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
        $Property = 'display',

        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Description = 'Please Choose from the Menu:'
    )

    $SelectionOptions = $Options | ForEach-Object {
        return @{
            name        = $_.GetType().BaseType -IS [System.ValueType] -OR $_.GetType().Name -EQ "String" ? $_ : ($_."$Property")
            returnValue = $_
        }
    }

    # [System.Console]::WriteLine seems a bit more performent
    $_reset_ = "`e[0m"
    $_linebreak_ = "`n"
    $_highlightPage_ = "`e[47m`e[90m"
    $_highlightSelect_ = "`e[45m"
    $_highlightSearch_ = "`e[46m"

    $reservedLines = 8
    $initialSelectionSize = [System.Math]::Max($Host.UI.RawUI.WindowSize.Height, 10)
    $selectionIndexOnPage = 0
    $currentPage = 0

    $searchString = ''
    $prefixSelected = ' => '
    $prefixNonSelected = '    '
    $shortendSuffix = '... '

    $reservedWidth = [System.Math]::Max($prefixSelected.length, $prefixNonSelected.length) + 4
    $initialSelectionWitdh = $Host.UI.RawUI.WindowSize.Width - $reservedWidth - $shortendSuffix.Length

    try {

        do {
            [System.Console]::CursorTop = 0
            [System.Console]::CursorVisible = $false
            # [System.Console]::Clear()
            Clear-Host
        
            $DescriptionEndocded = ("**$($Description.trim() -replace '_+', ' ')**" | ConvertFrom-Markdown -AsVT100EncodedString).VT100EncodedString
            [System.Console]::WriteLine($DescriptionEndocded)


            # Filter Options !!! Wrap in Array to make sure to still have an array, when only one element remains. !!!
            $filteredOptions = @($SelectionOptions | Where-Object { $_.name.toLower() -Like "*$($searchString.ToLower())*" })


            # Do page and selection calculations.
            $maxSelectionsPerPage = $initialSelectionSize - $reservedLines
            $totalCountOfPages = [System.Math]::Ceiling($filteredOptions.Count / $maxSelectionsPerPage)
            $lastPageMaxIndex = $totalCountOfPages -GT 1 ? ($filteredOptions.Count % $maxSelectionsPerPage - 1) : ($filteredOptions.Count - 1)

            # Fix if current Page is out-of-range.
            $currentPage = $currentPage -GE $totalCountOfPages ? $totalCountOfPages - 1 : $currentPage


            # Caluclation for current Page
            $isLastPage = $currentPage -EQ ($totalCountOfPages - 1)
            $selectionPageOffset = $currentPage * $maxSelectionsPerPage
            $selectionIndexOnPage = ($selectionIndexOnPage -GT $lastPageMaxIndex) -AND $isLastPage ? $lastPageMaxIndex : $selectionIndexOnPage


            $filteredOptions 
            | Select-Object -Skip $selectionPageOffset 
            | Select-Object -First $maxSelectionsPerPage 
            | ForEach-Object { $index = 0 } {

                $displayedText = $_.Name.Substring(0, [System.Math]::Min($_.Name.length, $initialSelectionWitdh))
                $displayedText += $_.Name.length -GT $initialSelectionWitdh ? $shortendSuffix : ''

                if ($index -eq $selectionIndexOnPage) {
                    $displayedText = @(
                        $prefixSelected, $_highlightSelect_, $displayedText, $_reset_
                    ) -join ''
                    [System.Console]::WriteLine($displayedText)
                } 

                else {

                    $startIndex = $displayedText.toLower().IndexOf($searchString.toLower())
                    $firstPart = $displayedText.Substring(0, $startIndex)
                    $highlightedPart = $displayedText.Substring($startIndex, [System.Math]::Max($searchString.Length, 0))
                    $lastPart = $displayedText.Substring($startIndex + $searchString.Length)

                    $displayedText = @(
                        $prefixNonSelected, $firstPart, $_highlightSearch_, $highlightedPart, $_reset_, $lastPart
                    ) -join ''
                    [System.Console]::WriteLine($displayedText)
                }

                $index++

            }

            if ($totalCountOfPages -gt 0) {
                $displayedText = @(
                    $_linebreak_, $_highlightPage_, "$($currentPage+1)/$totalCountOfPages", $_reset_
                ) -join ''
                [System.Console]::Write($displayedText)
            }
    
            if ($searchString.Length -gt 0) {
                $displayedText = @(
                    '     Searching For: ', $_highlightSearch_, "'$SearchString'", $_reset_, " | Remaining $($filteredOptions.Count) of $($Options.Count) Elements"
                ) -join ''
                [System.Console]::Write($displayedText)
            }
                            
            [System.Console]::WriteLine()

            # Process and switch key presses
            Switch ([System.Console]::ReadKey($true)) {
    
                { $_.Key -eq [System.ConsoleKey]::Enter } {
                    return $filteredOptions[$currentPage * $maxSelectionsPerPage + $selectionIndexOnPage].returnValue
                }

                { $_.Key -EQ [System.ConsoleKey]::Escape } {
                    throw "Operation was Cancelled due to pressing '$($_.Key)'"
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
