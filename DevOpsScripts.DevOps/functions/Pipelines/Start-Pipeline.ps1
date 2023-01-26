
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


    $Pipeline = Get-DevOpsPipelines | Where-Object -Property name -EQ -Value $name
    
    # Run Pipeline from Branch, dev or master
    if ($environment -eq 'Branch') {
        $currentBranch = git branch --show-current
        $build = Start-PipelineOnBranch -id $Pipeline.id -ref "refs/heads/$currentBranch"
    }

    if ($environment -eq 'dev' -OR $environment -eq 'both') {
        $build = Start-PipelineOnBranch -id $Pipeline.id -ref 'refs/heads/dev'
    }

    if ($environment -eq 'master' -OR $environment -eq 'both') {
        $build = Start-PipelineOnBranch -id $Pipeline.id -ref 'refs/heads/master'
    }

  
    Write-Host -Foreground Green '      '
    Write-Host -Foreground Green " 🎉 Started Pipeline '$($Pipeline.folder)/folder$($Pipeline.name)'  on $environment 🎉  "
    Write-Host -Foreground Green '      '

    Open-BuildInBrowser -buildId $build.id

}