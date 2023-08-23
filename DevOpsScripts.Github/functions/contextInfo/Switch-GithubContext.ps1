function Switch-GithubContext {

    param(
        # The specific Context to use
        [parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = (Get-GithubContexts).login
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [validateScript(
            {
                $_ -in (Get-GithubContexts).login
            }
        )]
        [System.String]
        $Context
    )

    return Set-GithubCache -Object $Context -Identifier git.context -Forever

}