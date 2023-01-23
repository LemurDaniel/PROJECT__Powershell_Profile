
function Start-Pipeline {
    
    [cmdletbinding()]
    param (
        [Parameter()]
        [ValidateScript(
            {
                $_ -in (Get-DevOpsPipelines 'name')
            }
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = Get-DevOpsPipelines 'name'
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        $Name,


        [Parameter()]
        [ValidateSet('Branch', 'Dev', 'Master', 'Both')]
        [System.String]
        $environment = 'Branch',

        [Parameter()]
        [switch]
        $Multiple
    )


    $Organization = Get-DevOpsCurrentContext -Organization
    $projectNameUrlEncoded = (Get-ProjectInfo 'name') -replace ' ', '%20'
    $Pipeline = Get-DevOpsPipelines | Where-Object -Property name -EQ -Value $name
    
    # Run Pipeline from Branch, dev or master
    if ($environment -eq 'Branch') {
        $currentBranch = git branch --show-current
        Start-PipelineOnBranch -id $Pipeline.id -ref "refs/heads/features/$currentBranch"
    }

    if ($environment -eq 'dev' -OR $environment -eq 'both') {
        Start-PipelineOnBranch -id $Pipeline.id -ref 'refs/heads/dev'
    }

    if ($environment -eq 'master' -OR $environment -eq 'both') {
        Start-PipelineOnBranch -id $Pipeline.id -ref 'refs/heads/master'
    }

    # Open in Browser.
    $pipelineUrl = "https://dev.azure.com/$Organization/$projectNameUrlEncoded/_build?definitionId=$($Pipeline.id)"

    Write-Host -Foreground Green '      '
    Write-Host -Foreground Green " 🎉 Started Pipeline '$($Pipeline.folder)/folder$($Pipeline.name)'  on $environment 🎉  "
    Write-Host -Foreground Green "    $pipelineUrl "
    Write-Host -Foreground Green '      '

    Start-Process $pipelineUrl

}