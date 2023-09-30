
<#

.SYNOPSIS
    Same as terraform state rm, but with autocompletion.

.DESCRIPTION
    Same as terraform state rm, but with autocompletion.


.LINK
  

#>


function Remove-TerraformState {

    [Alias('staterm')]
    param (
        # Module path in the terraform state.
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
            
                $validValues = terraform state list
                            
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $ModulePath
    )


    terraform state rm $ModulePath
    
}