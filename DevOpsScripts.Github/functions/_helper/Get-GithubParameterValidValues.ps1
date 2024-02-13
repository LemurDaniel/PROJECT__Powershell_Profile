
function Get-GithubParameterValidValues {

    [CmdletBinding()]
    param(
        # The name of the powershell parameter
        [Parameter(
            Mandatory = $true
        )]
        $ParameterName,

        # The hashtable of bound powrshell parameters.
        [Parameter(
            Mandatory = $true
        )]
        [System.Collections.Hashtable]
        $BoundParameters
    )

    $Identifier = @{
        Account    = $BoundParameters['Account']
        Context    = $BoundParameters['Context']
        Repository = $BoundParameters['Repository']
    }
    
    switch ($parameterName) {

        'Account' {
            return (Get-GithubAccountContext -ListAvailable).name
        }

        'Context' {
            return (Get-GithubContexts -Account $Identifier.Account).login
        }

        'Organization' {
            return Get-GithubContexts -Account $Identifier.Account
            | Where-Object -Property IsOrgContext -EQ $true
            | Select-Object -ExpandProperty login
        }

        'Repository' {
            return Get-GithubContextInfo -Account $Identifier.Account -Context $Identifier.Context
            | Select-Object -ExpandProperty repositories
            | Select-Object -ExpandProperty Name
        }

        'Issue' {
            return Get-GithubIssues @Identifier
            | Select-Object -ExpandProperty title
        }

        'IssueOpen' {
            return Get-GithubIssues @Identifier
            | Where-Object -Property state -EQ open
            | Select-Object -ExpandProperty title
        }

        'Workflow' {
            return Get-GithubWorkflow @Identifier
            | Select-Object -ExpandProperty file_name
        }

        'Branch' {
            return Get-GithubBranch @Identifier
            | Select-Object -ExpandProperty name
        }

        'Ref' {
            return Get-GithubRef @Identifier
            | Select-Object -ExpandProperty ref
        }

        'SecretsTemplate' {
            return Get-GithubSecretsTemplate -ListAvailable
        }

        'Gitignore' {
            return Get-GithubIgnoreTemplate
        }

        'CodeEditor' {
            return (Get-CodeEditor -ListAvailable).Keys
        }

        'Tab' {
            return (Get-GithubRepositoryTabs).Keys
        }

        default {
            Write-Error "'Parameter '$parameterName' is not supported!'"
        }
    }
}
