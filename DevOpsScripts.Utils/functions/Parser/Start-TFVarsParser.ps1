Using module './classes/AstNodeType.psm1'
Using module './classes/Parser.psm1'


# Not finishied. Very Very basic attempt at a parser. This is not supposed to be a Full-Parser, just very basic attempt.
function Start-TFVarsParser {
    param (
        [Parameter(Mandatory = $false)]
        [System.String]
        $test = @'

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

'@
    )
    
    $Configuration = @(

        [AstNodeType]::new('WHITESPACE', '^\s+', $true),
        [AstNodeType]::new('COMMENT', @('^#[^\n]+', '^\/\*[\s\S]*?\*\/'), $true),
        [AstNodeType]::new('IGNORE', @('^;'), $true),

        [AstNodeType]::new('SEPERATOR', '^\n+')

        [AstNodeType]::new('BLOCK_END', '^}'),
        [AstNodeType]::new('BLOCK_START', '^{'),

        [AstNodeType]::new('ARRAY_END', '^\]'),
        [AstNodeType]::new('ARRAY_START', '^\['),
        [AstNodeType]::new('ARRAY_SEPERATOR', '^,'),

        [AstNodeType]::new('STRING', "^`"[^`"]*`"|^'[^']*'"),
        [AstNodeType]::new('NUMBER', '^\d+')

        [AstNodeType]::new('VARIABLE', '^[A-Za-z_0-9]{1}[A-Za-z_0-9]*')

        [AstNodeType]::new('ASSIGNMENT', '^=')
    )

    return [Parser]::new($Configuration).parse($test) | ConvertTo-Json -Depth 99
}

#Start-TFVarsParser