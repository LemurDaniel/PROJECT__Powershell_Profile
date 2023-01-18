function Update-ModuleSourcesInPath {

  [cmdletbinding(
    SupportsShouldProcess,
    ConfirmImpact = 'high'
  )]
  param (
    [Parameter()]
    [System.String]
    $replacementPath = $null,

    [Parameter()]
    [switch]
    $forceApiCall = $false
  )

  $totalReplacements = [System.Collections.ArrayList]::new()
  $taggedRepositories = Get-RecentSubmoduleTags -forceApiCall:($forceApiCall)
  $replacementPath = $null -ne $replacementPath -AND $replacementPath.Length -gt 0 ? $replacementPath : ((Get-Location).Path) 
  
  # Implements Confirmation
  if ($PSCmdlet.ShouldProcess("$replacementPath" , 'Do Subfolder Regex-Operations')) {

    # Make Regex Replace on all Child-Items.
    $childitems = Get-ChildItem -Recurse -Path ($replacementPath) -Filter '*.tf' 
    foreach ($tfConfigFile in $childitems) {

      $regexMatchesCount = 0
      $Content = Get-Content -Path $tfConfigFile.FullName

      if ($null -eq $Content -OR $Content.Length -eq 0) {
        continue; # Skip empty files to prevent errors
      }

      # Parse all Repos over file
      foreach ($repository in $taggedRepositories) {
        $regexMatches = [regex]::Matches($Content, $repository.regexQuery)

        :regexMatch foreach ($match in $regexMatches) {             
          $sourcePath = $match.Value.replace('"', '').split('?ref=')

          # Skip sources with already most current tag set.
          if ($sourcePath[1] -eq $repository.CurrentTag) {
            continue regexMatch;
          }

          $regexMatchesCount += 1
          $sourcePath[0] = $sourcePath[0].replace('source', '').replace('=', '').trim()
          $sourceWithCurrentTag = "source = `"$($sourcePath[0])?ref=$($repository.CurrentTag)`""
          # -replace is used, since get-content returns an array of lines of file, not a text string.
          # And -replace works on Arrays as well, unlike .replace
          $matcher = $match.Value.Replace('/', '\/').Replace('?', '\?').Replace('.', '\.')
          $Content = $Content -replace $matcher, $sourceWithCurrentTag
                
        }
      }
      # Only out-file when changes happend. Overwriting files with the same content, caused issues with VSCode git extension
      if ($regexMatchesCount -gt 0) {
        $totalReplacements.Add($tfConfigFile.FullName)
        $Content | Out-File -LiteralPath $tfConfigFile.FullName
      }
    }  
  }

  return $totalReplacements
}