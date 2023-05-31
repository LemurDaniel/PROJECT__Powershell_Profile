<#
    .SYNOPSIS
    Update all terraform-submodule sources on an location. (DC Migration specific)

    .DESCRIPTION
    Update all terraform-submodule sources on an location. (DC Migration specific)

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None.

    .LINK
        
#>
function Update-ModuleSourcesInPath {

    [cmdletbinding(
        SupportsShouldProcess,
        ConfirmImpact = 'high'
    )]
    param (
        # The Name of the Project. If null will default to current Project-Context.
        [Parameter(
            Mandatory = $false,
            Position = 0
        )]
        [ValidateScript(
            { 
                $null -eq $_ -OR [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-DevOpsProjects).name
            },
            ErrorMessage = 'Please specify a correct Projectname.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-DevOpsProjects).name 
                        
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Project = "DC Azure Migration",
        
        # The Name of the Repository. If null will default to current repository where command is executed.
        [Parameter(
            Mandatory = $false,
            Position = 1
        )]
        [ValidateScript(
            { 
                $true #[System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-ProjectInfo repositories.name)
            },
            ErrorMessage = 'Please specify a correct Name.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
                        
                $validValues = Get-ProjectInfo -Name $fakeBoundParameters['Project'] -return 'repositories.name'
                        
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Name,

        # The Root path of all terraform configuration files. Defaults to the current execution location.
        [Parameter()]
        [System.String]
        $replacementPath = $null,

        # Refresh the submodule tags, fetched from Azure DevOps.
        [Parameter()]
        [switch]
        $refresh
    )

    $totalReplacements = [System.Collections.ArrayList]::new()
    $taggedRepositories = Get-RecentSubmoduleTags -Project $Project -refresh:$refresh
    if ($PSBoundParameters.ContainsKey("Name")) {
        $taggedRepositories = $taggedRepositories | Where-Object { $_.Name -eq $Name }
    }

    $replacementPath = ![System.String]::IsNullOrEmpty($replacementPath) ? $replacementPath : ((Get-Location).Path) 
  
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
                $null = $totalReplacements.Add($tfConfigFile.FullName)
                $Content | Out-File -LiteralPath $tfConfigFile.FullName
            }
        }  
    }

    return $totalReplacements
}
