


function New-WindowBindings {

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true
        )]
        [System.Windows.Window]
        $Window,

        # Various Parameters to change in ui. The Key refers to the x:Name identifier.
        # Can be a Name and a hastable with attribute values. Scriptblock cause method invocations for event_handlers.
        [Parameter(
            Mandatory = $true
        )]
        [System.Collections.Hashtable]
        $Bind
    )

    $Bind.GetEnumerator() | ForEach-Object {

        $attributes = $_.Key.split('.') 
        $UIobject = $Window.FindName($attributes[0])
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

    return $Window
}