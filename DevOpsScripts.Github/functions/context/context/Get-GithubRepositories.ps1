<#
    .SYNOPSIS
    Get Github repositories for a context.

    .DESCRIPTION
    Get Github repositories for a context.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Repositories

    
    .LINK
        
#>
function Get-GithubRepositories {

    param(
        # The name of the github account to use. Defaults to current Account.
        [Parameter(
            Position = 3,
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Account' })]
        [System.String]
        [Alias('a')]
        $Account,

        # The Name of the Github Context to use. Defaults to current Context.
        [Parameter(
            Mandatory = $false,
            Position = 2
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Context' })]
        [System.String]
        [Alias('c')]
        $Context,


        [Parameter()]
        [switch]
        $Refresh
    )

    $Cache = Get-GithubCache -Identifier "repositories.$Context" -Account $Account
    if ($null -eq $Cache -OR $Refresh) {
       
        $Account = (Get-GithubAccountContext -Account $Account).name
        if ($Context -eq (Get-GithubUser -Account $Account).login) {
            $Request = @{
                Method      = 'GET'
                API         = '/user/repos'
                affiliation = 'owner'
                visibility  = 'all'
            }
        }
        else {
            $Request = @{
                Method  = 'GET'
                Context = $Context
                API     = '/orgs/{org}/repos'
            }
        }

        $gitRepositories = Invoke-GithubRest @Request -Account $Account
        | Select-Object *, 
        @{
            Name       = 'Account';
            Expression = {
                $Account
            }
        },
        @{
            Name       = 'Context'; 
            Expression = { 
                $_.owner.login 
            }
        },
        @{
            Name       = 'LocalPath';
            Expression = {
                $Context = Get-GithubContexts -Account $Account 
                | Where-Object -Property login -EQ $_.owner.login
                return Join-Path -Path $Context.LocalPath -ChildPath $_.Name
            }
        }

        $Cache = Set-GithubCache -Object ($gitRepositories ?? @{}) -Identifier "repositories.$Context" -Account $Account

    }

    return $Cache
}
