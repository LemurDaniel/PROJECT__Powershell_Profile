function Invoke-GithubGenericArgumentCompleter {
    param ( 
        [Parameter()]
        [System.String]
        $commandName,

        [Parameter()]
        [System.String]
        $parameterName,

        [Parameter()]
        [System.String]
        $wordToComplete,

        [Parameter()]
        $commandAst,

        [Parameter()]
        $fakeBoundParameters
    )

    $validValues = $null
    $Identifier = @{
        Account    = $fakeBoundParameters['Account']
        Context    = $fakeBoundParameters['Context']
        Repository = $fakeBoundParameters['Repository']
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
            throw [System.InvalidOperationException]::new("Parameter '$parameterName' is not supported!")
        }
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