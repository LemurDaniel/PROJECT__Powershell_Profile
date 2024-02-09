function Invoke-GithubGenericValidateScript {
    param(
        # The value to validate.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Value,

        # The hashtable of bound powrshell parameters.
        [Parameter(
            Mandatory = $true
        )]
        [System.Collections.Hashtable]
        $BoundParameters,

        # The name of the parameter to validate.
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $ParameterName
    )

    $validValues = $null
    $Identifier = @{
        Account    = $BoundParameters['Account']
        Context    = $BoundParameters['Context']
        Repository = $BoundParameters['Repository']
    }
    
    switch ($parameterName) {

        'Account' {
            $validValues = (Get-GithubAccountContext -ListAvailable).name
        }

        'Context' {
            $validValues = (Get-GithubContexts -Account $Identifier.Account).login
        }

        'Repository' {
            $validValues = Get-GithubContextInfo -Account $Identifier.Account -Context $Identifier.Context
            | Select-Object -ExpandProperty repositories
            | Select-Object -ExpandProperty Name
        }

        'Issue' {
            $validValues = Get-GithubIssues @Identifier
            | Select-Object -ExpandProperty title
        }

        'IssueOpen' {
            $validValues = Get-GithubIssues @Identifier
            | Where-Object -Property state -EQ open
            | Select-Object -ExpandProperty title
        }

        'Workflow' {
            $validValues = Get-GithubWorkflow @Identifier
            | Select-Object -ExpandProperty file_name
        }

        'Branch' {
            $validValues = Get-GithubBranches @Identifier
            | Select-Object -ExpandProperty name
        }

        'CodeEditor' {
            $validValues = (Get-CodeEditor -ListAvailable).Keys
        }

        'Tab' {
            $validValues = (Get-GithubRepositoryTabs).Keys
        }

        default {
            return "'Parameter '$parameterName' is not supported!'"
        }
    }


    $isValid = [System.String]::IsNullOrEmpty($Value) -OR $Value -IN $validValues

    if (!$isValid) {
        Write-Error "`n`n*** '$Value' is not a valid value for '$ParameterName'! ***`n`n"
    }

    return $true
}