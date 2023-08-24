function Switch-GithubContext {

    [Alias('github-swc')]
    param(
        [Parameter(
            Position = 1,
            Mandatory = $false
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-UtilsCache -Identifier context.accounts.all -AsHashTable).keys
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                [System.String]::IsNullOrEmpty( $_) -OR $_ -in (Get-UtilsCache -Identifier context.accounts.all -AsHashTable).keys
            },
            ErrorMessage = 'Not a valid account.'
        )]
        $Account,

        # The specific Context to use
        [parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = (Get-GithubContexts -Account $fakeBoundParameters['Account']).login
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $Context
    )

    if ($Context -notin (Get-GithubContexts -Account $Account).login) {
        throw "Context '$Context' not existent in '$Account'"
    }

    $Account = [System.String]::IsNullOrEmpty($Account) ? (Get-GithubAccountContext).name : $Account
    $Account = Switch-GithubAccountContext -Account $Account
    $Context = Set-GithubCache -Object $Context -Identifier git.context -Account $Account -Forever

    Write-Host -ForegroundColor Magenta "Account: $Account"
    Write-Host -ForegroundColor Magenta "Context: $Context"

}