
<#
    .SYNOPSIS
    Replacements for a full redeployment test. (DC Migration specific)

    .DESCRIPTION
    Replacements for a full redeployment test. (DC Migration specific)

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None.


    .LINK
        
#>

function Edit-RepositoriesForRedeployment {

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
        $Redownload,

        [Parameter()]
        [switch]
        $ImportRepositories
    )

    $projectSource = Get-ProjectInfo -refresh -Name 'DC Azure Migration'
    $projectTarget = Get-ProjectInfo -refresh -Name 'DC ACF Redeployment'

    ####################################
    # Import Repositories
    ####################################

    if ($ImportRepositories) {

        $pat = Get-PAT -Organization baugruppe -Name redploymentImport -HoursValid 1 -PatScopes app_token 


        $projectSource.repositories | Sort-Object -Property name | ForEach-Object {

            $existentRepository = $projectTarget.repositories | Where-Object -Property name -EQ -Value $_.name 
            if ($existentRepository) {
                $DeletionRepositoryPoll = Select-ConsoleMenu -Property display -Description "'$($_.name)' already exists in the Project '$($projectTarget.name)'" `
                    -Options @(
                    @{ display = 'Open in Browser fon MANUALLY Deletion'; option = 0 }
                    @{ display = 'Skip this Repository'; option = 1 }
                )

                if ($DeletionRepositoryPoll.option -eq 0) {
                    Start-Process $existentRepository.webUrl
                }
                elseif ($DeletionRepositoryPoll.option -eq 1) {
                    return
                }
            }


            $ImportRepositoryPoll = Select-ConsoleMenu -Property display `
                -Description "Import '$($_.name)' in the Project '$($projectTarget.name)'" `
                -Options @(
                @{ display = 'Continue importing this Repository'; option = 0 }
                @{ display = 'Skip this Repository'; option = 1 }
            )
            
            if ($ImportRepositoryPoll.option -eq 1) {
                return
            }
            # Do Manually , to aviod accidental deletions.
            #$Request = @{
            #    Project = $projectTarget.name
            #    Method  = 'DELETE'
            #    SCOPE   = 'PROJ'
            #    API     = "/_apis/git/repositories/$($existentRepository.id)?api-version=7.0"
            #}
            #$null = Invoke-DevOpsRest @Request
    
            $Request = @{
                Project = $projectTarget.name
                Method  = 'POST'
                SCOPE   = 'PROJ'
                API     = '/_apis/git/repositories?api-version=7.0'
                Body    = @{
                    name = $_.name
                }
            }
            $repository = Invoke-DevOpsRest @Request


            try {

                $Request = @{
                    Method = 'POST'
                    SCOPE  = 'ORG'
                    API    = '/_apis/serviceendpoint/endpoints?api-version=7.0'
                    Body   = @{
                        authorization                    = @{
                            scheme     = 'UsernamePassword'
                            parameters = @{
                                username = $null
                                password = $pat.password | ConvertFrom-SecureString -AsPlainText
                            }
                        }
                        type                             = 'git'
                        name                             = "endpoint-o.O-$($projectSource.id)-$($_.webUrl)"
                        url                              = $_.webUrl
                        serviceEndpointProjectReferences = @(
                            @{ 
                                projectReference = @{
                                    id   = $projectSource.id
                                    name = $projectSource.Name
                                }
                                name             = "endpoint-o.O-$($projectSource.id)-$($_.webUrl)"
                            },
                            @{ 
                                projectReference = @{
                                    id   = $projectTarget.id
                                    name = $projectTarget.Name
                                }
                                name             = "endpoint-o.O-$($projectTarget.id)-$($_.webUrl)"
                            }
                        )
                    }
                }
                $serviceEndpoint = Invoke-DevOpsRest @Request

                Start-Sleep -Milliseconds 500
                # Import Repository
                $Request = @{
                    Project = $projectTarget.name
                    Method  = 'POST'
                    SCOPE   = 'PROJ'
                    API     = "/_apis/git/repositories/$($repository.id)/importRequests?api-version=7.0"
                    Body    = @{
                        parameters = @{
                            serviceEndpointId = $serviceEndpoint.id
                            tfvcSource        = $null
                            gitSource         = @{
                                overwrite = $false
                                url       = $_.webUrl
                            }
                        }
                    }
                }
                Invoke-DevOpsRest @Request

                Start-Process $repository.webUrl

            }
            catch {
                Write-Host -ForegroundColor Red $_
            }
            finally {
                $Request = @{
                    Method = 'DELETE'
                    SCOPE  = 'ORG'
                    API    = "/_apis/serviceendpoint/endpoints/$($serviceEndpoint.id)?api-version=7.0"
                    Query  = @{
                        projectIds = @($projectSource.id, $projectTarget.Id) -join ','
                    }
                }
                Invoke-DevOpsRest @Request
            }
        }
    }

    ####################################
    # Redownload Repositories
    ####################################

    if ($Redownload) {
        $projectTarget.respositories | ForEach-Object {
            Open-Repository -Project 'DC ACF Redeployment' -Name $_.name -onlyDownload -replace 
        }
    }
    
    ####################################
    # Regex Replacements
    ####################################

    Set-Location -Path $projectTarget.Projectpath

    $replacingMappings.GetEnumerator() | ForEach-Object {
        Edit-RegexOnFiles -regexQuery $_.Key -replace $_.Value
    }


    ####################################
    # Non-Acf-Spn
    ####################################
    
    $repositoryAcfMain = Get-RepositoryInfo -Project $projectTarget.name -Name terraform-acf-main

    $foundationTfVars = @()
    $foundationTfVars += Get-Item -Path "$($repositoryAcfMain.localPath)/landingzones/landingzone_acf_foundations/landingzone.dev.auto.tfvars"
    $foundationTfVars += Get-Item -Path "$($repositoryAcfMain.localPath)/landingzones/landingzone_acf_foundations/landingzone.prod.tfvars"

    $foundationTfVars | ForEach-Object {
        $parsedTfVar = Convert-TFVarsToObject -FilePath $_.FullName
    
        $parsedTfVar.governance_settings.management_groups.children_level_1.spn_role_assignments_non_acf
        $parsedTfVar.governance_settings.management_groups.children_level_2.spn_role_assignments_non_acf
    }

    ####################################
    # Appzone-references-owners
    ####################################

    $appzones = @()
    $appzones += Get-ChildItem -Path "$($repositoryAcfMain.localPath)/landingzones/landingzone_acf_appzone/configurations-dev" -Filter '*.json' -Recurse -File
    $appzones += Get-ChildItem -Path "$($repositoryAcfMain.localPath)/landingzones/landingzone_acf_appzone/configurations-prod" -Filter '*.json' -Recurse -File
 
    $appzones | ForEach-Object {  
    
        $content = Get-Content -Path $_.FullName | ConvertFrom-Json -Depth 99

        $changed = $false

        if ($null -ne $content.rbac.owners -AND $content.rbac.owners.Length -gt 0) {
            $content.rbac.owners = @()
            $changed = $true
        }
        if ($null -ne $content.rbac.owners_groups -AND $content.rbac.owners_groups.Length -gt 0) {
            $content.rbac.owners_groups = @()
            $changed = $true
        }

        if ($changed) {
            Write-Host -ForegroundColor Yellow $_.Name
            $content | ConvertTo-Json -Depth 99 | Out-File -FilePath $_.FullName
        }
        else {
            Write-Host -ForegroundColor Green $_.Name
        }
    }

    ####################################
    # naming-module
    ####################################

    ####################################
    # Rebase Master into Dev
    ####################################

    $PullRequest = @{
        Project        = $projectTarget.Name
        RepositoryName = $repositoryAcfMain.Name
        PRtitle        = 'Rebase Master Into Dev'
        Target         = 'dev'
        Source         = 'master'
        mergeStrategy  = 'Rebase' 
        autocompletion = $true
    }
    New-PullRequest @PullRequest
}

