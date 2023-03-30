
<#
    .SYNOPSIS
    Performs a regex replace operation on all files in a Folder or the current Folder.

    .DESCRIPTION
    Performs a regex replace operation on all files in a Folder or the current Folder.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    return the number of replacements


    .EXAMPLE

    Remove Moved-Blocks from Terraform configuration in current-Folder:

    PS> Edit-RegexOnFiles -regexQuery 'moved\s*\{[^\}]*\}'


    .LINK
        
#>

function Edit-RegexOnFiles {

    [cmdletbinding(
        SupportsShouldProcess,
        ConfirmImpact = 'high'
    )]
    param (
        # Root replacementpath. If not specified defaults to current location.
        [Parameter()]
        [System.String]
        $replacementPath = $null,

        # String to replace regex results with.
        [Parameter()]
        [System.String]
        $replace = '',

        # The Regexquery to perform on all files.
        [Parameter(Mandatory = $true)]
        [System.String]
        $regexQuery,

        # Filter for Filtering certain files.
        [Parameter(Mandatory = $false)]
        [System.String]
        $Filter = '*',

        # The Regexquery to perform on all files.
        [Parameter(Mandatory = $false)]
        [System.Text.RegularExpressions.RegexOptions[]]
        $regexOptions = @(
            [System.Text.RegularExpressions.RegexOptions]::Multiline
        )
    )

    $totalReplacements = [System.Collections.ArrayList]::new()
    $replacementPath = $null -ne $replacementPath -AND $replacementPath.Length -gt 0 ? $replacementPath : ((Get-Location).Path) 
  
    # Implements Confirmation handling.
    if ($PSCmdlet.ShouldProcess("$replacementPath" , 'Perform Regex Operations on Folder')) {

        # Make Regex Replace on all Child-Items.
        $childFiles = Get-ChildItem -Recurse -Path $replacementPath -Filter $Filter -File
        $totalHits = 0
        $progressId = Get-Random

        for ($index = 0; $index -lt $childFiles.Count; $index++) {

            $file = $childFiles[$index]
            $progress = [System.int32]($index / $childFiles.Count * 100)
            Write-Progress -Id $progressId -Activity 'Replacements' -Status "$($index+1) Files of $($childFiles.Count) | Total Hits $($totalHits)" -PercentComplete $progress
      
            # Find Regexmatches.
            $Content = Get-Content -Path $file.FullName -Raw
            if ($null -eq $Content -or $Content.Length -eq 0) {
                continue
            }
            $regexMatches = [regex]::Matches($Content, $regexQuery, $regexOptions)
            if (($regexMatches | Measure-Object).Count -le 0) {
                continue
            }
      
            #Write-Host -ForegroundColor Yellow ([System.String]::Format('{0:00} Hits |@{1}', $regexMatches.Count, $file.Name))
            $totalHits += $regexMatches.Count
            $Content = [regex]::replace($Content, $regexQuery, $replace, $regexOptions)
            $Content | Out-File -LiteralPath $file.FullName
        }  

        Write-Progress -Id $progressId -Activity 'Replacements' -Completed
    }
    return $totalReplacements
}

