
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


        # The Regexquery to perform on all files.
        [Parameter(Mandatory = $true)]
        [System.Text.RegularExpressions.RegexOptions[]]
        $regexOptions = @(
            [System.Text.RegularExpressions.RegexOptions]::Multiline
        )
    )

    $totalReplacements = [System.Collections.ArrayList]::new()
    $replacementPath = $null -ne $replacementPath -AND $replacementPath.Length -gt 0 ? $replacementPath : ((Get-Location).Path) 
  
    # Implements Confirmation handling.
    if ($PSCmdlet.ShouldProcess("$replacementPath" , 'Remove Moved-Blocks on Folderpath')) {

        # Make Regex Replace on all Child-Items.
        $childFiles = Get-ChildItem -Recurse -Path ($replacementPath) -Filter '*.tf' | `
            Select-Object -Property *, @{ 
            Name       = 'Content';
            Expression = {
                Get-Content -Raw -Path $_.FullName
            }
        } | Where-Object { $null -ne $_.Content -AND $_.Content.Length -ne 0 }


        foreach ($file in $childFiles) {

            # Find Regexmatches.
            $regexMatches = [regex]::Matches($file.Content, $regexQuery, $regexOptions)
            if (($regexMatches | Measure-Object).Count -le 0) {
                continue
            }
      
            Write-Host -ForegroundColor Yellow ([System.String]::Format('{0:00} Hits |@{1}', $regexMatches.Count, $file.Name))
            $file.Content = [regex]::replace($file.Content, $regexQuery, $replace, $regexOptions)
            $file.Content | Out-File -LiteralPath $file.FullName
        }  
    }

    return $totalReplacements
}

