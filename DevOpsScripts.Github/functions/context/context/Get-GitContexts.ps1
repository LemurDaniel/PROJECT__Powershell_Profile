<#
    .SYNOPSIS
    Get the Useraccount and Organzations connected to login

    .DESCRIPTION
    Get the Useraccount and Organzations connected to login

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Git contexts

    
    .LINK
        
#>

function Get-GitContexts {

    param(
        # The name of the Git account to use. Defaults to current Account.
        [Parameter(
            Position = 0,
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Account' })]
        [System.String]
        [Alias('a')]
        $Account,

        [Parameter()]
        [switch]
        $Refresh
    )

    # Location where to download repositories.
    $basePath = [System.String]::IsNullOrEmpty($env:GIT_RepositoryPath) ? "$env:USERPROFILE\git\repos" : $env:GIT_RepositoryPath

    $Cache = Get-GitCache -Identifier org.all -Account $Account
    if ($null -eq $Cache -OR $Refresh) {

        $AccountContext = Get-GitAccountContext -Account $Account

        $gitContexts = @()
        $gitContexts += Get-GitUser -Refresh:$Refresh -Account $AccountContext.name
        | Select-Object *, @{
            Name       = 'IsUserContext';
            Expression = { $true }
        },
        @{
            Name       = 'IsOrgContext';
            Expression = { $false }
        }

        $gitContexts += Invoke-GitRest -Method GET -API 'user/orgs' -Account $AccountContext.name
        | ForEach-Object { $_ }
        | Select-Object *, @{
            Name       = 'IsUserContext';
            Expression = { $false }
        },
        @{
            Name       = 'IsOrgContext';
            Expression = { $true }
        }

        $gitContexts = $gitContexts | Select-Object *, @{
            Name       = 'Account';
            Expression = {
                $AccountContext.name
            }
        }, @{
            Name       = 'Context';
            Expression = {
                $_.login
            }
        }, @{
            Name       = 'LocalPath';
            Expression = {
                "$basePath\GITHUB\$($AccountContext.name)\$($_.login)"
            }
        }
        $gitContexts | ForEach-Object {
            if (!(Test-Path $_.LocalPath)) {
                $null = New-Item -ItemType Directory -Path $_.LocalPath
            }
        }
        $Cache = Set-GitCache -Object $gitContexts -Identifier org.all -Account $Account
    }

    return $Cache
}
