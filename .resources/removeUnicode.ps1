Invoke-ScriptInRepositories `
    -Project 'DC Azure Migration' `
    -workitemTitle 'remove invisible unicode char and replace with whitespace' `
    -ScriptBlock `
{ 
    param($Repository, $Project)  
    
    Remove-InvisibleUnicode -Path $Repository.Localpath -Recurse
    
}