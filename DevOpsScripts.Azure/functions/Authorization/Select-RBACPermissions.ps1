<#
    .SYNOPSIS
    Selects and Gets Information about any available RBAC-Permission.

    .DESCRIPTION
    Selects and Gets Information about any available RBAC-Permission.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    A list of all RBAC-Permission from the Parameters specified.


    .EXAMPLE

    Get all Read Data-Plane Actions for Microsoft.Storage:

    PS> Select-RBACPermissions Microsoft.Storage -actionType read -dataActions

    .EXAMPLE

    Get all Read Data-Plane Actions for Microsoft.Storage Blobs:

    PS> Select-RBACPermissions Microsoft.Storage blob -dataActions

    .EXAMPLE

    Get all administrative read operations for Microsoft.Compute:

    PS> Select-RBACPermissions Microsoft.Compute -actionType read


    .EXAMPLE

    Get all operation names for administrative read operations for Microsoft.Compute:

    PS> Select-RBACPermissions Microsoft.Compute -actionType read -return "Operation Name"

    .LINK
        
#>

function Select-RBACPermissions {

    param (
        # The name of the Resource Provider.
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ValidateScript(
            { 
                $_ -in (Get-RBACPermissions -AsHashtable).Keys
            },
            ErrorMessage = 'Please specify the correct Provider.'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-RBACPermissions -AsHashtable).Keys
                
                $validValues | `
                    Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } | `
                    ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $ResourceProvider,

        # A set of tags to search for in the action description.
        [Parameter(
            Position = 1,
            Mandatory = $false
        )]
        [System.String[]]
        $tags = '*',

        # A specific action type to return.
        [Parameter(Mandatory = $false)]
        [ValidateSet(
            'read',
            'write',
            'delete',
            'action',
            'any'
        )]
        [System.String]
        $actionType = 'any',

        # Switch to return data actions instead of administrative actions.
        [Parameter()]
        [switch]
        $dataActions,


        # The Property to return from the items. If null will return full Properties.
        [Alias('return')]
        [Parameter()]
        [System.String]
        $Property
    )

    $permissions = Get-RBACPermissions
    | Select-Object -ExpandProperty $ResourceProvider 
    | Where-Object -Property 'Data Action' -EQ -Value $dataActions 
    | Where-Object { $actionType -eq 'any' -OR $_.'Operation Name' -like "*$actionType" }
    
    return Search-In $permissions -where 'Operation Description' -has $tags -Multiple -return $Property

}
