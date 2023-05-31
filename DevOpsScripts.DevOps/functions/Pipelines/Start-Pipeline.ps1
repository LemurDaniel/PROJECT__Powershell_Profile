
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
    
    [cmdletbinding(
        DefaultParameterSetName = 'currentContext'
    )]
    param (
        # The name of the Project to swtich to in which you want to open a repository. Will default to curren tproject context.
        [Parameter(
            ParameterSetName = 'Projectspecific',
            Mandatory = $false,
            Position = 2
        )]   
        [ValidateScript(
            { 
                [System.String]::IsNullOrEmpty($_) -OR $_ -in (Get-DevOpsProjects).name
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
        $Project,

        # The Name of the Pipeline in the Current Project.
        [Parameter(
            ParameterSetName = 'Projectspecific',
            Mandatory = $true,
            Position = 0
        )]
        [Parameter(
            ParameterSetName = 'currentContext',
            Mandatory = $false,
            Position = 0
        )]   
        [ValidateScript(
            { 
                # NOTE cannot access Project when changes dynamically with tab-completion
                $true 
            },
            ErrorMessage = 'Please specify an correct Name.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = Get-DevOpsPipelines -Project $fakeBoundParameters['Project']
                
                $validValues.name | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Name,

        # Where to start the Pipeline. Master/Dev or Current-Branch of repository.
        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [ValidateSet('Branch', 'Dev', 'Master', 'Both')]
        [System.String]
        $environment = 'Branch',

        # Switch to skip opening in the browser
        [switch]
        $noBrowser
    )


    $Project = Get-ProjectInfo -Name $Project | Select-Object -ExpandProperty name
    $Pipeline = Get-DevOpsPipelines -Project $Project | Where-Object -Property name -EQ -Value $name
    
    # Run Pipeline from Branch, dev or master
    $builds = @()
    if ($environment -eq 'Branch') {
        $currentBranch = git branch --show-current
        $builds += Start-PipelineOnBranch -Project $Project -id $Pipeline.id -ref "refs/heads/$currentBranch"
    }

    if ($environment -eq 'dev' -OR $environment -eq 'both') {
        $builds += Start-PipelineOnBranch -Project $Project -id $Pipeline.id -ref 'refs/heads/dev'
    }

    if ($environment -eq 'master' -OR $environment -eq 'both') {
        $builds += Start-PipelineOnBranch -Project $Project -id $Pipeline.id -ref 'refs/heads/master'
    }

  
    Write-Host -Foreground Green '      '
    Write-Host -Foreground Green " 🎉 Started Pipeline$($builds.length -gt 1 ? 's' : '') '$($Pipeline.folder)/$($Pipeline.name)'  on $environment 🎉  "
    Write-Host -Foreground Green '      '

    if (!$noBrowser) {
        $builds | ForEach-Object {
            Open-BuildInBrowser -Project $Project -buildId $_.id
        }
    }

}