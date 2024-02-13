<#
    .SYNOPSIS
    Adds or Updates a Variable in a Github-Organization via API.

    .DESCRIPTION
    Adds or Updates a Variable in a Github-Organization via API.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .LINK
        
#>

function Set-GithubOrganizationVariable {

    [CmdletBinding(
        DefaultParameterSetName = "Single"
    )]
    param (
        # The name of the github account to use. Defaults to current Account.
        [Parameter(
            Position = 3,
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Account' })]
        [System.String]
        [Alias('a')]
        $Account,

        # The Name of the Github Context to use. Defaults to current Context.
        [Parameter(
            Mandatory = $false,
            Position = 2
        )]
        [ArgumentCompleter({ Invoke-GithubGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GithubGenericValidateScript $_ $PSBoundParameters 'Context' })]
        [System.String]
        [Alias('c')]
        [Alias('context')]
        $Organization,


        
        # The name of the variable.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "Single"
        )]
        [System.String]
        $Name,

        # The value of the variable.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "Single"
        )]
        [System.String]
        $Value,

        # The hashtable of variable names and values to add to the repository.
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "Hashtable"
        )]
        [System.Collections.Hashtable]
        $Variables,

        # The visibility of the variable accross the organization.
        [parameter()]
        [validateSet('all', 'selected', 'private')]
        [System.String]
        $Visibility = 'all'
    )

    $contextData = Get-GithubContextInfo -Account $Account -Context $Organization
    $contextInfo = @{
        Account = $contextData.Account
        Context = $contextData.Context
    }

    if (!$PSBoundParameters.ContainsKey("Variables")) {
        $Variables = [System.Collections.Hashtable]::new()
        $null = $Variables.add($Name, $Value)
    }

    $existingVariables = Get-GithubOrganizationVariable @contextInfo

    $Variables.GetEnumerator() 
    | ForEach-Object {

        $Request = @{
            METHOD  = $null
            API     = "/orgs/$($contextInfo.Context)/actions/variables"
            Account = $contextInfo.Account
            Body    = @{
                name       = $_.Key
                value      = $_.Value
                visibility = $Visibility
            }
        }

        if ($_.Key -in $existingVariables.name) {
            $Request.METHOD = "PATCH"
            $Request.API = "/orgs/$($contextInfo.Context)/actions/variables/$($_.Key)"
            Write-Host -ForegroundColor GREEN "Updating Variable '$($_.Key)'"
        }
        else {
            $Request.METHOD = "POST"
            Write-Host -ForegroundColor GREEN "Adding Variable '$($_.Key)'"
        }

        $null = Invoke-GithubRest @Request
    }
    
}