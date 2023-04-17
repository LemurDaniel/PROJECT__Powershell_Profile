
# Dishing out those Pull-Requests
Invoke-ScriptInRepositories `
    -Project 'DC Azure Migration' `
    -workitemTitle 'Remove Devcontainer from repositories' `
    -ScriptBlock `
{ 
    param($Repository, $Project)  
    
    Get-ChildItem -Path $Repository.Localpath -Filter '.devcontainer' | Remove-Item -Recurse 
    
}