
<#
    .SYNOPSIS
    Loads a XAML-File to a .NET WPF-Window.

    .DESCRIPTION
    Loads a XAML-File to a .NET WPF-Window.

    .INPUTS
    None. You cannot Pipe Object into the Function.

    .OUTPUTS
    A Window.


    .LINK
        
#>

function New-WindowWPF {

    [CmdletBinding()]
    param (
        # The path to an xaml-file with a Window-Definiton.
        [Parameter(
            Mandatory = $true
        )]
        [System.Object]
        $Path,


        # Various Parameters to change in ui. The Key refers to the x:Name identifier.
        # Can be a Name and a hastable with attribute values. Scriptblock cause method invocations for event_handlers.
        [Parameter(
            Mandatory = $false
        )]
        [System.Collections.Hashtable]
        $Bind = @{}
    )

    try {
        $reader = [System.Xml.XmlNodeReader]::Create((Get-Item $Path))
        $window = [System.Windows.Markup.XamlReader]::Load($reader)
        $window.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterScreen
        $null = $window.Activate()
        #$null = New-WindowBindings -Window $window -Bind $Bind        

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

# Create a window from a XAMl which apperently causes all necessery assemblies to be loaded?
$window = New-WindowWPF -Path "$PSScriptRoot/template/empty.xaml"