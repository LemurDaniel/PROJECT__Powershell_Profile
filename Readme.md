

## Powershell Profile

Contains a few useful Functions for Calling DevOps-Api, Azure-Api, etc and Githug-Api.

1. Install Azure Az-Module.
2. Install/Import DevOpsScripts-Module

----

## Basic Steps DevOps-API:

Refers only to the DevOpsScripts-Module.

3. Run `Connect-AzAccount`.
4. Set the correct DevOps Context
   1. `Switch-Organization` - Short `swo`
   > `PS> swo <autocompleted_org_names> <autocompleted_project_names>`
   2. Project-Context can be switched in Organization with
   > `PS> swp <autocompleted_project_names>`
5. All DevOps related functions should now use current context.
   1. `Get-ProjectInfo` get info of current Project 
   2. `Get-RepositoryInfo` gets info about a repository in the curren Project.
   3. `Open-Repository` automatically downloads and opens repository in VScode (if on path)

----

## Basic Steps Github-API:

3. `Add-GithubAccountContext` (Multiple can be added each with its own PAT)
4. Set the Account-Context. Defaults to first account.
   1. `Switch-GithubAccountContext` or `github-swa`
   > `PS> github-swa -Account <autocompleted_account>`
5. Set the context. Defaults to users context.
   1. `Switch-GithubContext` or `github-swc`
   > `PS> github-swc -Context <autocompleted_context>`<br>
   > `PS> github-swc -Account <autocompleted_account> -Context <autocompleted_context>`
6. Use Module:
   1. `Get-GithubUser`
   2. `Get-GithubRepositoryInfo -Context <context> -Name <repo_name>`
   3. `gitvc -Context <context> -Name <repo_name>`
7. Add and siwtch Code-Editors for gitvc
   1. `Switch-DefaultCodeEditor -Name <autocompleted_name>`
   2. `Add-CodeEditor -Name <name> -path <path>`

#### Started out as Personal-Project, now Group-Effort of Team-DevOps:
- Tim Krehan
- Nicoals Neunert
- Daniel Landau
