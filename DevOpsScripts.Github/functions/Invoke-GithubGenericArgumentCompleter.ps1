function Invoke-GithubGenericArgumentCompleter {
    param ( 
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $commandName,

        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $parameterName,

        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $wordToComplete,

        [Parameter(
            Mandatory = $true
        )]
        $commandAst,

        [Parameter(
            Mandatory = $true
        )]
        [System.Collections.Hashtable]
        $fakeBoundParameters,

        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $alias
    )

    $validValues = $null
    $Identifier = @{
        Account    = $fakeBoundParameters['Account']
        Context    = $fakeBoundParameters['Context']
        Repository = $fakeBoundParameters['Repository']
    }
    
    $parameterName = [System.String]::IsNullOrEmpty($alias) ? $parameterName : $alias
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


    if ($null -EQ $validValues -OR $validValues.Count -EQ 0) {
        return "'<no values...>'"
    }

    return $validValues 
    | Where-Object { 
        if ($wordToComplete.Length -LT 3) {
            return $_.toLower() -like "$wordToComplete*".toLower() 
        }
        else {
            return $_.toLower() -like "*$wordToComplete*".toLower() 
        }
    } 
    | ForEach-Object { 
        $_ -match '\s' ? "'$_'" : $_
    } 
}