<#
    .SYNOPSIS
    Powershell git wrapper to handle non-error messages written to error-stream.

    .DESCRIPTION
    Powershell git wrapper to handle non-error messages written to error-stream.


    .EXAMPLE

    Use Invoke-GitWrapper via defined alias:

    PS> git-wrapper status --verbose


    .EXAMPLE

    Force Error and see results written to error stream:

    PS> $output = git-wrapper status --bla

#>

$env:gitCLIPath = (Get-Command -Name git -ErrorAction SilentlyContinue).Source 
function Invoke-GitWrapper {

    [Alias('git-wrapper')] # Can also Override/Overwrite actual actual git command with wrapper
    param (
        # All arguments passed after command.
        [Parameter(
            ValueFromRemainingArguments = $true
        )]
        [System.String[]]
        $Options
    )

    # Execute git writing everything to standard output
    $stdOutput = . $env:gitCLIPath $Options 2>&1
    if ($LASTEXITCODE -NOTIN ($null, 0)) {
        # Get the error message and convert array of line to string with linebreaks (So Write-Error can properly deal with it)
        $errorMessage = $stdOutput.Exception.Message -join [System.Environment]::NewLine
        # Write actual error to error output stream via powershell.
        Write-Error "(EXITCODE: $LASTEXITCODE)$([System.Environment]::NewLine)$errorMessage"

        # Optional use Exit in a pipeline scenario instead of Write-Error
        # [System.Environment]::Exit($LASTEXITCODE)
    }
    else {
        $stdOutput
    }
}

<#

compact:

$env:gitCLIPath = (Get-Command -Name git -ErrorAction SilentlyContinue).Source 
function Invoke-GitWrapper {
    [Alias('git')]param ([Parameter(ValueFromRemainingArguments = $true)][System.String[]]$Options)
    $stdOutput = . $env:gitCLIPath $Options 2>&1
    if ($LASTEXITCODE -NOTIN ($null, 0)) { Write-Error "(EXITCODE: $LASTEXITCODE)$([System.Environment]::NewLine)$($stdOutput.Exception.Message -join [System.Environment]::NewLine)" } else { $stdOutput }
}

#>