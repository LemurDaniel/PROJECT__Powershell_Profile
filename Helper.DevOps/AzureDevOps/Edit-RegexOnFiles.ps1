function Edit-RegexOnFiles {

    [cmdletbinding(
        SupportsShouldProcess,
        ConfirmImpact = 'high'
    )]
    param (
        [Parameter()]
        [System.String]
        $replacementPath = $null,

        # Parameter help description.
        [Parameter()]
        [System.String]
        $replace = '',

        # Parameter help description.
        [Parameter(Mandatory = $true)]
        [System.String]
        $regexQuery
    )

    $totalReplacements = [System.Collections.ArrayList]::new()
    $replacementPath = $null -ne $replacementPath -AND $replacementPath.Length -gt 0 ? $replacementPath : ((Get-Location).Path) 
  
    # Implements Confirmation handling.
    if ($PSCmdlet.ShouldProcess("$replacementPath" , 'Remove Moved-Blocks on Folderpath')) {

        # Make Regex Replace on all Child-Items.
        $childFiles = Get-ChildItem -Recurse -Path ($replacementPath) -Filter '*.tf' | `
            ForEach-Object { 
            [PSCustomObject]@{
                FullName = $_.FullName
                Content  = (Get-Content -Path $_.FullName -Raw)
            } 
        } | Where-Object { $null -ne $_.Content -AND $_.Content.Length -ne 0 }


        foreach ($file in $childFiles) {

            # Find Regexmatches.
            $regexMatches = [regex]::Matches($file.Content, $regexQuery)
            if (($regexMatches | Measure-Object).Count -le 0) {
                continue
            }
      
            :regexMatch 
            foreach ($match in $regexMatches) {     
                # -replace is used, since get-content returns an array of lines of file, not a text string.
                # And -replace works on Arrays as well, unlike .replace
                $file.Content = $file.Content -replace ($match.Value), $replace
            }

            $file.Content | Out-File -LiteralPath $file.FullName
        }  
    }

    return $totalReplacements
}

