
<#
    .SYNOPSIS
    Loads a XAML-File to a Window.

    .DESCRIPTION
    Loads a XAML-File to a Window.

    .INPUTS
    None. You cannot Pipe Object into the Function.

    .OUTPUTS
    A Window.

    .EXAMPLE



    .LINK
        
#>

function New-WindowFromXAML {

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true
        )]
        [System.Object]
        $Path
    )

    Add-Type -AssemblyName PresentationFramework

    try {
        $reader = [System.Xml.XmlNodeReader]::Create((Get-Item $Path))
        $window = [System.Windows.Markup.XamlReader]::Load($reader)
        $window.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterScreen

        # Note: Finally will also be executed on return.
        # https://stackoverflow.com/questions/345091/will-code-in-a-finally-statement-fire-if-i-return-a-value-in-a-try-block
        return $window
    }
    catch {
        throw $_
    }
    finally {
        $reader.Close()
    }

}
