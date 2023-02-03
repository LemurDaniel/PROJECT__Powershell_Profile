
<#
    .SYNOPSIS
    Loads a XAML-File to a Window.

    .DESCRIPTION
    Loads a XAML-File to a Window.

    .INPUTS
    None. You cannot Pipe Object into the Function.

    .OUTPUTS
    A Window.


    .LINK
        
#>

function New-WindowFromXAML {

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

        $Bind.GetEnumerator() | ForEach-Object {
            
            $attributes = $_.Key.split('.') 
            $UIobject = $window.FindName($attributes[0])

            if($null -eq $UIobject){
                throw "Cannot find an UI-Element with x:Name '$($_.Key)'"
            }

            $hashtable = $null -ne $_.Value -AND $_.Value.GetType() -eq [System.Collections.Hashtable] ? $_.Value : @{ $attributes[1] = $_.Value }

            $hashtable.GetEnumerator() | ForEach-Object {

                if($_.Value.getType() -eq [System.Management.Automation.ScriptBlock]){
                    $UIobject."$($_.Key)"($_.Value)
                }
                else {
                    $UIobject."$($_.Key)" = $_.Value
                }
            }

        }

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

Add-Type -AssemblyName PresentationFramework
# Create a window from a XAMl which apperently causes all necessery assemblies to be loaded?
$window = New-WindowFromXAML -Path "$PSScriptRoot/template/empty.xaml"