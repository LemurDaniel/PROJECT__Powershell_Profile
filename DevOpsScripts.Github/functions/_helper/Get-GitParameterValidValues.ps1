
function Get-GitParameterValidValues {

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
            return (Get-GitAccountContext -ListAvailable).name
        }

        'Context' {
            return (Get-GitContexts -Account $Identifier.Account).login
        }

        'Organization' {
            return Get-GitContexts -Account $Identifier.Account
            | Where-Object -Property IsOrgContext -EQ $true
            | Select-Object -ExpandProperty login
        }

        'Repository' {
            return Get-GitContextInfo -Account $Identifier.Account -Context $Identifier.Context
            | Select-Object -ExpandProperty repositories
            | Select-Object -ExpandProperty Name
        }

        'Issue' {
            return Get-GitIssues @Identifier
            | Select-Object -ExpandProperty title
        }

        'IssueOpen' {
            return Get-GitIssues @Identifier
            | Where-Object -Property state -EQ open
            | Select-Object -ExpandProperty title
        }

        'Workflow' {
            return Get-GitWorkflow @Identifier
            | Select-Object -ExpandProperty file_name
        }

        'Branch' {
            return Get-GitBranch @Identifier
            | Select-Object -ExpandProperty name
        }

        'Ref' {
            return Get-GitRef @Identifier
            | Select-Object -ExpandProperty ref
        }

        'SecretsTemplate' {
            return Get-GitSecretsTemplate -ListAvailable
        }

        'Gitignore' {
            return Get-GitIgnoreTemplate
        }

        'CodeEditor' {
            return (Get-CodeEditor -ListAvailable).Keys
        }

        'Tab' {
            return (Get-GitRepositoryTabs).Keys
        }

        default {
            Write-Error "'Parameter '$parameterName' is not supported!'"
        }
    }
}
