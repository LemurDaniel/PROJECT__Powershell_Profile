Using module './classes/AstNodeType.psm1'
Using module './classes/AstObjectConverter.psm1'
Using module './classes/Parser.psm1'

<#
    .SYNOPSIS
    Very Very Basic Parser with Limited Functionality to convert '.tfvars' File into a PSObject and from there to it's JSON-Representation.

    .DESCRIPTION
    Very Very Basic Parser with Limited Functionality to convert '.tfvars' File into a PSObject and from there to it's JSON-Representation.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    The PSObject Representation of the parsed Input.


    .EXAMPLE

    Convert Some Example '.tfvars' Data to a PSObject and then to JSON:

    PS> $object = Convert-TFVarsToObject -Content @'

# Set of tags for resource groups
tags = {
  govAccountable         = "name.surname@brz.eu"
  govBilling             = "Corporate"
  govResponsible         = "name.surname@brz.eu"
  govWorkloadDescription = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna"
}

data_actions = ["sss", "ssss", "adasdasd"]
testtesttest = [
    {  
        Property1 = 123
        Property2 = "123"
    }
]

'@

    PS> $object | ConvertTo-Json



    .LINK
        
#>

function Convert-TFVarsToObject {

    [CmdletBinding(
        DefaultParameterSetName = 'FilePath'
    )]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = 'FilePath'
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)
                $validValues = (Get-ChildItem -Filter '*tfvars*').name
                
                $validValues | `
                    Where-Object {
                    $_.toLower() -like ($wordToComplete.Length -lt 3 ? "$wordToComplete*" : "*$wordToComplete*").toLower() 
                } | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $FilePath,

        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'FilePath'
        )]
        [Switch]
        $OutFileJson,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Content'
        )]
        [System.String]
        $Content
    )
    
    $Configuration = @(

        [AstNodeType]::new('WHITESPACE', '^\s+', $true),
        [AstNodeType]::new('COMMENT', @('^#[^\n]+', '^\/\*[\s\S]*?\*\/'), $true),
        #[AstNodeType]::new('IGNORE', @('^;'), $true)
        #[AstNodeType]::new('SEPERATOR', '^\n+|^;+')


        [AstNodeType]::new('SEPERATOR', '^\n+')

        [AstNodeType]::new('BLOCK_END', '^}'),
        [AstNodeType]::new('BLOCK_START', '^{'),

        [AstNodeType]::new('ARRAY_END', '^\]'),
        [AstNodeType]::new('ARRAY_START', '^\['),
        [AstNodeType]::new('ARRAY_SEPERATOR', '^,'),

        
        [AstNodeType]::new('HEREDOC_STRING', '^<<-{0,1}(\w+)\s*\n((?:[\s\S])*?)\s*\n\s*\1[\s\n]{0,1}'),

        [AstNodeType]::new('VARIABLE', '^(?!false\b.*\n|true\b.*\n|null\b.*\n)[A-Za-z_]{1}[\w_\-]*\s+')

        [AstNodeType]::new('STRING', "^`"[^`"]*`"|^'[^']*'"),
        [AstNodeType]::new('BOOLEAN', '^true|^false'),
        [AstNodeType]::new('NULL', '^null'),
        [AstNodeType]::new('FLOAT', '^[+-]?\d+\.\d+')
        [AstNodeType]::new('NUMBER', '^[+-]?\d+')

        [AstNodeType]::new('ASSIGNMENT', '^=')
    )

    if ($PSBoundParameters.ContainsKey('FilePath')) {
        $Content = Get-Content -Path $FilePath -Raw
    }

    $parsed = [Parser]::new($Configuration).parse($Content)
    $psObject = [AstObjectConverter]::Convert($parsed)

    if ($PSBoundParameters.ContainsKey('FilePath') -AND $OutFileJson) {
        $FileInfo = Get-Item -Path $FilePath
        $psObject | ConvertTo-Json -Depth 99 | Out-File -Path "$($FileInfo.Directory.FullName)/$($FileInfo.BaseName).json"
    }

    return $psObject
}

<#

Convert-TFVarsToObject -Content @'

# Terraform lower level remote State
lowerlevel_subscription_id      = "24234342-24-234-234-24"
lowerlevel_resource_group_name  = "rg-launchpad-dev-001"
lowerlevel_storage_account_name = "stbrzacfstatedev001"
lowerlevel_container_name       = "acf-level2-hub"
lowerlevel_key                  = "landingzone_acf_hub.tfstate"

# Environment Variables
convention  = "" # Sourced from landingzone_acf_hub
prefix      = "" # Sourced from landingzone_acf_hub
environment = "" # Sourced from landingzone_acf_hub
location    = "westeurope"

# Set of tags for resource groups
tags = {
  govAccountable         = "name.surname@brz.eu"
  govBilling             = "Corporate"
  govBusinessCriticality = "Medium"
  govCompany             = "123456789"
  govCostCenter          = "123456789"
  govDeploymentType      = "IaC"
  govResponsible         = "name.surname@brz.eu"
  govWorkloadDescription = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna"
}

data_actions = ["sss", "ssss"

, "adasdasd"
]

testtesttest = [
    {  
        Property1 = 123
        Property2 = "123"
    }
]

permissions = {
  actions      = ["*"]
  data_actions = []
  not_actions = [
    "Microsoft.ManagedIdentity/userAssignedIdentities/assign/action",
    "Microsoft.ManagedIdentity/userAssignedIdentities/write",
    "Microsoft.ManagedIdentity/userAssignedIdentities/delete",
    "Microsoft.Authorization/classicAdministrators/write",
    "Microsoft.Authorization/elevateAccess/action",
    "Microsoft.Authorization/locks/write",
    "Microsoft.Authorization/locks/delete",
    "Microsoft.Authorization/policyDefinitions/write",
    "Microsoft.Authorization/policyDefinitions/delete",
    "Microsoft.Authorization/policyAssignments/write",
    "Microsoft.Authorization/policyAssignments/delete",
    "Microsoft.Authorization/policySetDefinitions/write",
    "Microsoft.Authorization/policySetDefinitions/delete",
    "Microsoft.Authorization/roleDefinitions/delete",
    "Microsoft.Authorization/roleDefinitions/write",
    "Microsoft.Management/managementGroups/subscriptions/delete",
    "Microsoft.Management/managementGroups/subscriptions/write",
    "Microsoft.Management/managementGroups/write",
    "Microsoft.Network/virtualNetworks/peer/action",
  ]
  not_data_actions = []
}

heredocString = <<EOF 
    asasfasf
    fflflfl
    assas
    EOF


  bool1 = true
  bool2 = false
  nullValued = null

  Property123 = {
    "string" = {
        bla = true
        blabla = false
    }
    "string2" = {
        bla = true
        blabla = false

        heredocString2 = <<QUERY 
            asasfasf
            fflflfl
            assas
        QUERY
    }
}

positiveNumber = [1, 2, 3]
negativeNumbers = [-1, -2, -3]

positiveFloats = [1.023, 2.012, 3.001]
negativeFloats = [-1.44, -2.99, -3.34]
'@

#>
