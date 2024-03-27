
<#
    .SYNOPSIS
    Invokes a script block accross all repositories in a project an creates Pull Requests on Changes.

    .DESCRIPTION
    Invokes a script block accross all repositories in a project an creates Pull Requests on Changes.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None.


    .LINK
        
#>

function Invoke-GitScriptInRepositories {

    [cmdletbinding(
        DefaultParameterSetName = 'fromPipeline',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'high'
    )]
    param (
        # Repositories to iterate over.
        [Parameter(
            ParameterSetName = 'fromPipeline',
            ValueFromPipeline = $true,
            Mandatory = $true,
            Position = 0
        )]
        [System.Object]
        $Repository,

        # The commit message.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Message,

        # The name of the Pull Request.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $PullRequestTitle,

        # The name of the branch to commit into. Defaults to default branch.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Branch,
                
        # The script block to invoke in every repository.
        [Parameter(
            Mandatory = $true
        )]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock

    )

    BEGIN {}

    PROCESS {
   
        Write-Host
        Write-Host '---------------------------------------------------------------------------'

        $Identifier = @{
            Account    = $Repository.Account
            Context    = $Repository.Context
            Repository = $Repository.Name
        }

        $null = Open-GitRepository @Identifier -onlyDownload
        $Repository = Get-GitRepositoryInfo @Identifier

        Write-Host
        Write-Host -ForegroundColor Yellow "Processing '$($Identifier.Repository)' in '$($Identifier.Account)'"
        Write-Host

        $randomHex = New-RandomBytes -Type Hex -Bytes 2
        $stashName = "$workItemTitle-$randomHex" -replace '\s', '_' -replace '[^\sA-Za-z0-9\\-]*', ''
  
        git -C $Repository.LocalPath add -A
        git -C $Repository.LocalPath stash push -m $stashName
        git -C $Repository.LocalPath checkout $repositoryInfo.default_branch
        git -C $Repository.LocalPath pull origin $repositoryInfo.default_branch


        & $ScriptBlock -Repository $Repository -Identifier $Identifier


        if ([System.String]::IsNullOrEmpty($PullRequestTitle) -OR [System.String]::IsNullOrEmpty($Message)) {
            git -C $Repository.LocalPath stash apply "stash^{/$stashName}" 2>$null
            return
        }


        $changes = git -C $Repository.LocalPath status --porcelain | Measure-Object
        if ($changes.Count -GT 0) {
    
            Write-Host -ForegroundColor Yellow "Detected Changes in Repository '$($Repository.full_name)'"
                        
            if ($PSCmdlet.ShouldProcess($repository.Name , 'Open repository in VS Code for additional changes.')) {
                $null = Open-Repository @Identifier
            }
            
            if ($PSCmdlet.ShouldProcess($repository.Name , 'Create Pull Request?')) {
          
                git -C $Repository.LocalPath add -A
                git -C $Repository.LocalPath commit -m $Message
                git -C $Repository.LocalPath push

                $PullRequest = @{
                    Account    = $Identifier.Account
                    Context    = $Identifier.Context
                    Repository = $Identifier.Repository
                    Base       = [System.String]::IsNullOrEmpty($Branch) ? $Repository.default_branch : $Branch
                    Title      = $PullRequestTitle
                }
                New-GitPullRequest @PullRequest
            } 
            else {
                git -C $Repository.LocalPath reset --hard
            }

        }

        git -C $Repository.LocalPath stash apply "stash^{/$stashName}" 2>$null
      
    }

    END {}
}