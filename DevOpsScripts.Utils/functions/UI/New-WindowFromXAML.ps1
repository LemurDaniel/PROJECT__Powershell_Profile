
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

    Add-Type -AssemblyName PresentationFramework

    try {
        $reader = [System.Xml.XmlNodeReader]::Create((Get-Item $Path))
        $window = [System.Windows.Markup.XamlReader]::Load($reader)
        $window.WindowStartupLocation = [System.Windows.WindowStartupLocation]::CenterScreen
        $null = $window.Activate()

        $Bind.GetEnumerator() | ForEach-Object {
            
            if($_.Value.GetType() -eq [System.Collections.Hashtable]){
                $UIobject = $window.FindName($_.Key)

                if($null -eq $UIobject){
                    throw "Cannot find an UI-Element with x:Name '$($_.Key)'"
                }

                $_.Value.GetEnumerator() | ForEach-Object {

                    if($_.Value.getType() -eq [System.Management.Automation.ScriptBlock]){
                        $UIobject."$($_.Key)"($_.Value)
                    }
                    else {
                        $UIobject."$($_.Key)" = $_.Value
                    }
                }
            }

            else {
                # TODO
                $attributes = $_.Key.split('.') 
                $UIobject = $window.FindName($attributes[0])

                if($null -eq $UIobject){
                    throw "Cannot find an UI-Element with x:Name '$($attributes[0])'"
                }

                if($null -ne $_.Value -AND $_.Value.getType() -eq [System.Management.Automation.ScriptBlock]){
                    $UIobject."$($attributes[1])"($_.Value)
                }
                else {
                    $UIobject."$($attributes[1])" = $_.Value
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
