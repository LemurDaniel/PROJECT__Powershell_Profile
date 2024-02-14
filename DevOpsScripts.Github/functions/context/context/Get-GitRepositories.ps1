<#
    .SYNOPSIS
    Get Git repositories for a context.

    .DESCRIPTION
    Get Git repositories for a context.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Repositories

    
    .LINK
        
#>
function Get-GitRepositories {

    param(
        # The name of the Git account to use. Defaults to current Account.
        [Parameter(
            Position = 1,
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Account' })]
        [System.String]
        [Alias('a')]
        $Account,

        # The Name of the Git Context to use. Defaults to current Context.
        [Parameter(
            Mandatory = $false,
            Position = 0
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Context' })]
        [System.String]
        [Alias('c')]
        $Context,


        [Parameter()]
        [switch]
        $Refresh
    )

    $Cache = Get-GitCache -Identifier "repositories.$Context" -Account $Account
    if ($null -eq $Cache -OR $Refresh) {
       
        $Account = (Get-GitAccountContext -Account $Account).name
        if ($Context -eq (Get-GitUser -Account $Account).login) {
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

        $gitRepositories = Invoke-GitRest @Request -Account $Account
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
                $Context = Get-GitContexts -Account $Account 
                | Where-Object -Property login -EQ $_.owner.login
                return Join-Path -Path $Context.LocalPath -ChildPath $_.Name
            }
        }

        $Cache = Set-GitCache -Object ($gitRepositories ?? @{}) -Identifier "repositories.$Context" -Account $Account

    }

    return $Cache
}
