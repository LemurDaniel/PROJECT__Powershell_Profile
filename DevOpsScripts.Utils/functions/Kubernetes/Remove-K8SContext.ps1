


<#
    .SYNOPSIS
    Removes a context from the .kube/config file.

    .DESCRIPTION
    Removes a context from the .kube/config file.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .EXAMPLE

    Remove a autocompleted context:

    PS> Remove-K8SContext <autocompleted_context>

    .LINK
        
#>

function Remove-K8SContext {

    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param (
        # The name of the context.
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [System.String]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)

                $validValues = (Get-K8SContexts).name
                
                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [ValidateScript(
            {
                $_ -in (Get-K8SContexts).cluster
            }
        )]
        $Context
    )

    if ($PSCmdlet.ShouldProcess($Context, "Delete Context")) {
        $null = kubectl config delete-context $Context 
        Write-Host -ForegroundColor Magenta "Deleted Context: '$Context'"
    }
}

