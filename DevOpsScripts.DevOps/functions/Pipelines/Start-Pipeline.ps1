
<#
    .SYNOPSIS
    Start a specific Pipeline in the Current Project-Context and open the build in the Browser.

    .DESCRIPTION
    Start a specific Pipeline in the Current Project-Context and open the build in the Browser.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Start a Pipeline and open the build in the Browser:

    PS> Start-Pipeline '<Pipeline_name>'


    .LINK
        
#>
function Start-Pipeline {
    
    [cmdletbinding()]
    param (
        # The Name of the Pipeline in the Current Project.
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

        # Where to start the Pipeline. Master/Dev or Current-Branch of repository.
        [Parameter()]
        [ValidateSet('Branch', 'Dev', 'Master', 'Both')]
        [System.String]
        $environment = 'Branch'
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