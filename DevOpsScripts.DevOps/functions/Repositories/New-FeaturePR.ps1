
<#
    .SYNOPSIS
    Creates a new Pull-Request from Feature to Dev based on the Current Repository Location.

    .DESCRIPTION
    Creates a new Pull-Request from Feature to Dev based on the Current Repository Location.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None.

    .LINK
        
#>
function New-FeaturePR {

    param(
        # The target branch.
        [Parameter(
            Position = 0
        )]
        [ArgumentCompleter(   
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = @('dev', 'default')
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }    
        )]
        [System.String]
        $Target = 'dev', 

        # Enable autcompletion of PR.
        [Parameter()]
        [switch]
        $autocompletion,

        # Delete Local branch
        [Parameter()]
        [switch]
        $deleteLocalBranch
    )


    New-PullRequest -Target $Target -autocompletion:$autocompletion -deleteSourceBranch
    if ($deleteLocalBranch) {
        $currentBranchName = git branch --show-current
        git branch checkout (Get-RepositoryInfo).defaultBranch
        git branch -d $currentBranchName
    }
}