
<#
    .SYNOPSIS
    Creates a new Pull-Request from Feature to Dev based on the Current Repository Location.

    .DESCRIPTION
    Creates a new Pull-Request from Feature to Dev based on the Current Repository Location.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None.

    .EXAMPLE

    Create a Pull Request from the current Feature Branch to Dev:

    ps> New-Feature-PR

    .EXAMPLE

    Create a Pull Request from the current Feature Branch to Master with autocompletion enabled:

    ps> New-Feature-PR -autocompletion -Target master

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
        $target = 'dev', 

        # The Merge strategy for autocompletion enabled.
        [Parameter(
            Position = 1
        )]
        [ValidateSet(
            'noFastForward',
            'rebase',
            'rebaseMerge',
            'squash'
        )]
        [System.String]
        $mergeStrategy = 'noFastForward',

        # Enable autcompletion of PR.
        [Parameter()]
        [switch]
        $autocompletion,

        # Delete Local branch
        [Parameter()]
        [switch]
        $deleteLocalBranch
    )

    # Testing something
    #($MyInvocation.MyCommand.Parameters.Keys `
    #| ForEach-Object { Get-Variable -Name $_ -ErrorAction SilentlyContinue } ) `
    #| ForEach-Object {
    #    $PSBoundParameters[$_.Name] = $PSBoundParameters.containsKey($_.Name) ? $PSBoundParameters[$_.Name] : $_.Value
    #}

    New-PullRequest -Target $target -mergeStrategy $mergeStrategy -deleteSourceBranch -autocompletion:$autocompletion
    if ($deleteLocalBranch) {
        $currentBranchName = git branch --show-current
        git checkout (Get-RepositoryInfo).defaultBranch.replace('refs/heads/', '')
        git branch -d $currentBranchName
    }
}