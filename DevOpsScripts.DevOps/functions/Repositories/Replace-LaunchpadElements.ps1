
<#
    .SYNOPSIS
    Replacements for a full redeployment test.

    .DESCRIPTION


    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS



    .LINK
        
#>

function Replace-LaunchpadElements {

    [cmdletbinding(
        SupportsShouldProcess,
        ConfirmImpact = 'high'
    )]
    param (
        # Root replacementpath. If not specified defaults to current location.
        [Parameter()]
        [System.String]
        $replacingMappings = @{
            'kv-brzacflp'                             = 'kv-brzrdlp'
            'stbrzacfstate'                           = 'stbrzacfrdstate'
            'DC Azure Migration'                      = 'DC ACF Redeployment'
            'DC%20sAzure%20sMigration'                = 'DC%20ACF%20Redeployment'

            'ref=\d+'                                 = 'ref=master'
            
            'b207-aadmin@baugruppe.onmicrosoft.com'   = 'nicolas.neunert_brz.eu#EXT#@NBGRedeploymentTest.onmicrosoft.com'
            'b550-aadmin@baugruppe.onmicrosoft.com'   = 'Tim.Krehan_brz.eu#EXT#@NBGRedeploymentTest.onmicrosoft.com'
            'm01947-aadmin@baugruppe.onmicrosoft.com' = 'daniel.landau_brz.eu#EXT#@NBGRedeploymentTest.onmicrosoft.com'

            # Tenant Id
            '7ecb8dff-97cb-4f4a-94d3-86a4b39a84f2'    = 'be0b9f44-0aee-447a-90b1-688ac0334c2c'

            # Subscriptions
            'b8eb9adb-ae92-4c0b-9bbe-bf93f4fff832'    = '9d202099-1a17-4ca8-8d8a-51f5c362e6a1'
            '85e593c8-6040-4af4-8a20-a44e21d2cf7c'    = '779acae5-e165-443a-be4a-52e1d7a76ee3'
            'ff82009b-1acc-4075-b7af-9bfa99032699'    = 'e47ad692-f775-4235-80f0-891dbbacbc8d'
            '537784f2-4980-4662-96d5-8d35755470a8'    = '81bf7d7c-4d94-4f46-94eb-d4f656170560'
            'ef82acf3-4029-495f-883e-c373f4e9cf06'    = '31cb9167-78e0-424b-adab-db0b7de2d5cc'
            '072d6f1c-3034-4a2d-b1de-24b65cffa2a7'    = 'bd62c868-a382-4a35-ae34-56bbf238d83d'
            'd2679079-717f-4672-82ef-a4d96eab6609'    = 'f47f2e84-9389-4b84-8f6d-b7a3bc812424'
            'd733176f-3fbb-4a75-bf1e-b99ca0100f88'    = '6bec0d4b-6897-43bf-b590-44ade7bb1652'
            'b4c101de-f071-43f1-a0a1-ace490569c80'    = '24568084-af5a-4d68-9e15-3563ea69655a'
            '868df04e-be67-4008-9b3c-1d1e0cd87149'    = '0757123f-f099-488b-9b97-a2d6babc0c00'
            '9a409a66-191c-4f96-be61-114d20960c36'    = '037fa037-3096-4e63-8c1d-5846d04312d3'
            '1894b80c-5c59-487d-8a59-512fcf4756c8'    = 'bcdf356c-2248-433a-a1d3-3b1727560ac7'
            'ca072d4a-aff4-4243-9e2b-e130252edcf4'    = 'e153a52f-bd99-4700-95a2-2d0d028a6b97'
            'b13ce129-ea46-49b7-bb59-2260c129ecec'    = '1e4a32db-53fb-4be8-9baa-bbac936cede3'
            '7ab6827e-5303-45f8-9633-d6fb9d050f33'    = 'db1277e0-10e5-4511-8863-96f2091c396b'
            '2d9d5854-9933-4a66-9a83-8eda9a51fff3'    = 'e8bf9bf6-b629-48e3-854e-c8087416d075'
            '3a9f8896-6764-4c53-b7ff-4f40a5f24ab5'    = '3717497d-b88d-4882-8192-bc44eb7f87aa'
            'd97e41ea-4111-4b02-a074-2c350d42550c'    = 'c02981ae-4010-4698-a4eb-4981a167af2c'
            '93644b9f-d702-4207-8aef-cfc30f602e61'    = '2692258c-dc4e-4a96-901f-4c803dfc386b'
        },

        [Parameter()]
        [switch]
        $preventRedownload
    )

    $project = Get-ProjectInfo -Name 'DC ACF Redeployment'
    if ($preventRedownload) {
        $project.respositories | ForEach-Object {
            Open-Repository -Project 'DC ACF Redeployment' -Name $_.name -onlyDownload -replace 
        }
    }

    Set-Location -Path $project.Projectpath

    $replacingMappings.GetEnumerator() | ForEach-Object {
        Edit-RegexOnFiles -regexQuery $_.Key -replace $_.Value
    }

    # TODO
    # Appzone-references-owners
    # non_acf_spns
    # naming-module
}

