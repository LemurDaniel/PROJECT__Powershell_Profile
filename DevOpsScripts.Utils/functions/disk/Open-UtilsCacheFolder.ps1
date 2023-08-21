

<#
    .SYNOPSIS
    Opens the folder where cache files are save. For testing.

    .DESCRIPTION
    Opens the folder where cache files are save. For testing.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    Return the cached object.


    .LINK
        
#>
function Open-UtilsCacheFoler {

    [CmdletBinding()]
    param (

        # open in vscode. defaults to explorer
        [Parameter(
            # ParameterSetName = "code"
        )]
        [validateSet('explorer', 'code')]
        $tool = 'explorer'
    )

    $CacheFolderPath = ![System.String]::IsNullOrEmpty($Path) ? $Path : $env:UTILS_CACHE_PATH ?? "$([System.IO.Path]::GetTempPath())/.cache/"
    switch ($tool) {
        code { 
            return code $CacheFolderPath
        }

        Default {
            return Start-Process $CacheFolderPath
        }
    }
}