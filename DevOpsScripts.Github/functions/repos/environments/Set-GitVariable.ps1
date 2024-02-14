<#
    .SYNOPSIS
    Adds or Updates a Variable in a Git-Repository via API.

    .DESCRIPTION
    Adds or Updates a Variable in a Git-Repository via API.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None


    .EXAMPLE

    Adding/Updating a secret to the repository on the current path:

    PS> Set-GitVariable -Name "VariableName" -Value "Value"

    .EXAMPLE

    Adding/Updating multiple secrets to the repository on the current path:

    PS> Set-GitVariable -Variables @{
        Secret1 = "Value1"
        Secret2 = "Value2"
    }

    .EXAMPLE

    Adding/Updating a secret in a specific environment in the repository on the current path:

    PS> Set-GitVariable -Environment dev -Name "VariableName" -Value "Value"

    .EXAMPLE

    Adding/Updating multiple secrets in a specific environment in the repository on the current path:

    PS> Set-GitVariable -Environment dev -Variables @{
        Secret1 = "SecretValue"
        Secret2 = "SecretValue"
    }

    .LINK
        
#>

function Set-GitVariable {

    [CmdletBinding(
        DefaultParameterSetName = "Single"
    )]
    param (
        # The name of the Git account to use. Defaults to current Account.
        [Parameter(
            Position = 3,
            Mandatory = $false
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Account' })]
        [System.String]
        [Alias('a')]
        $Account,

        # The Name of the Git Context to use. Defaults to current Context.
        [Parameter(
            Mandatory = $false,
            Position = 2
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Context' })]
        [System.String]
        [Alias('c')]
        $Context,

        # The Name of the Git Repository. Defaults to current Repository.
        [Parameter(
            Mandatory = $false,
            Position = 0
        )]
        [ArgumentCompleter({ Invoke-GitGenericArgumentCompleter @args })]
        [ValidateScript({ Invoke-GitGenericValidateScript $_ $PSBoundParameters 'Repository' })]
        [System.String]
        [Alias('r')]
        $Repository,


        # The Environment to set the variable in. Leaving this empty creates a Repository variable.
        [Parameter(
            Mandatory = $false
        )]
        [System.String]
        $Environment,

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
        $Variables
    )

    $repositoryData = Get-GitRepositoryInfo -Account $Account -Context $Context -Name $Repository

    if (!$PSBoundParameters.ContainsKey("Variables")) {
        $Variables = [System.Collections.Hashtable]::new()
        $null = $Variables.add($Name, $Value)
    }


    $remoteUrl = "/repos/$($repositoryData.full_name)/actions/variables"
    if (![System.String]::IsNullOrEmpty($Environment)) {
        $remoteUrl = "/repositories/$($repositoryData.id)/environments/$Environment/variables"
    }

    $existingVariables = Invoke-GitRest -API $remoteUrl -Account $Account

    $Variables.GetEnumerator() 
    | ForEach-Object {

        $Request = @{
            METHOD  = $null
            API     = $remoteUrl
            Account = $repositoryData.Account
            Body    = @{
                name  = $_.Key
                value = $_.Value
            }
        }

        if ($_.Key -in $existingVariables.variables.name) {
            $Request.METHOD = "PATCH"
            $Request.API = "$remoteUrl/$($_.Key)"
            Write-Host -ForegroundColor GREEN "Updating Variable '$($_.Key)'"
        }
        else {
            $Request.METHOD = "POST"
            Write-Host -ForegroundColor GREEN "Adding Variable '$($_.Key)'"
        }

        $null = Invoke-GitRest @Request
    }
    
}