<#
    .SYNOPSIS
    Saves an encrypted template for secrets to deploy on a repository.

    .DESCRIPTION
    Saves an encrypted template for secrets to deploy on a repository.

    .INPUTS
    None. You cannot pipe objects into the Function.

    .OUTPUTS
    None

    .LINK

{
    "repository_secrets": {},
    "repository_variables": {},
    "environment_secrets": [
        {
            "environment_name": "dev",
            "secrets": {}
        }
    ],
    "environment_variables": [
        {
            "environment_name": "dev",
            "variables": {}
        }
    ]
}
#>

function Save-GithubRepositorySecretsTemplate {

    [CmdletBinding()]
    param (
        # The name of the template
        [Parameter(
            Mandatory = $true
        )]
        [System.String]
        $Name,

        [Parameter(
            Mandatory = $true
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete)

                return (Get-ChildItem -Filter '*.json' -Recurse -Depth 3) 
                | ForEach-Object {
                    return @{
                        file = $_.Name
                        path = $_.FullName.replace((Get-Location).Path, '')
                    }
                }
                | Where-Object {
                    $_.file.toLower() -like ($wordToComplete.Length -lt 3 ? "$wordToComplete*" : "*$wordToComplete*").toLower() 
                } 
                | Select-Object -ExpandProperty path
                | ForEach-Object { 
                    $_.contains(' ') ? "'$_'" : $_ 
                } 
            }
        )]
        $TemplateFilePath
    )

    $templateFile = @{
        repository_secrets    = @{}
        repository_variables  = @{}
        environment_secrets   = @()
        environment_variables = @()
    }
    
    $TemplateFilePath = Resolve-Path -Path "$((Get-Location).Path)/$TemplateFilePath"
    $data = Get-Content -Path $TemplateFilePath | ConvertFrom-Json -AsHashtable

    if ($data.ContainsKey('repository_secrets')) {
        $data['repository_secrets'].GetEnumerator()
        | ForEach-Object {
            $jsonValue = $_.Value.GetType() -EQ [System.String] ? $_.Value : ($_.Value | ConvertTo-Json -Compress)
            $null = $templateFile['repository_secrets'].add($_.Key, $jsonValue)
        }
    }
    if ($data.ContainsKey('repository_variables')) {
        $data['repository_variables'].GetEnumerator() 
        | ForEach-Object {
            $jsonValue = $_.Value.GetType() -EQ [System.String] ? $_.Value : ($_.Value | ConvertTo-Json -Compress)
            $null = $templateFile['repository_variables'].add($_.Key, $jsonValue)
        }
    }
    
    if ($data.ContainsKey('environment_secrets')) {
        $data['environment_secrets'] 
        | ForEach-Object {
            if (!$_.ContainsKey("environment_name")) {
                throw [System.InvalidOperationException]::new("File is invalid! Missing 'environment_name'")
            }
            if (!$_.ContainsKey("secrets") -OR $Null -EQ $_['secrets']) {
                $_['secrets'] = @{}
            }
    
            $environmentDefinition = @{
                environment_name = $_['environment_name']
                secrets          = @{}
            }
    
            $_['secrets'].GetEnumerator() 
            | ForEach-Object {
                $jsonValue = $_.Value.GetType() -EQ [System.String] ? $_.Value : ($_.Value | ConvertTo-Json -Compress)
                $null = $environmentDefinition['secrets'].add($_.Key, $jsonValue)
            }
    
            $templateFile['environment_secrets'] += $environmentDefinition
        }
    }
    
    if ($data.ContainsKey('environment_variables')) {
        $data['environment_variables'] 
        | ForEach-Object {
            if (!$_.ContainsKey("environment_name")) {
                throw [System.InvalidOperationException]::new("File is invalid! Missing 'environment_name'")
            }
            if (!$_.ContainsKey("variables") -OR $Null -EQ $_['variables']) {
                $_['variables'] = @{}
            }
    
            $environmentDefinition = @{
                environment_name = $_['environment_name']
                variables        = @{}
            }
    
            $_['variables'].GetEnumerator() 
            | ForEach-Object {
                $jsonValue = $_.Value.GetType() -EQ [System.String] ? $_.Value : ($_.Value | ConvertTo-Json -Compress)
                $null = $environmentDefinition['variables'].add($_.Key, $jsonValue)
            }
    
            $templateFile['environment_variables'] += $environmentDefinition
        }
    }

    $templates = Get-UtilsCache -Identifier "github.secrets_templates.all" -AsHashtable
    if ($null -EQ $templates) {
        $templates = [System.Collections.Hashtable]::new()
    }

    if (!$templates.ContainsKey($Name)) {
        $templates.add($Name, (New-RandomBytes hex 8))
    }

    $templateFile = $templateFile | ConvertTo-Json -Depth 99
    $null = Save-SecureStringToFile -PlainText $templateFile -Identifier "github.$($templates[$Name])"
    $null = Set-UtilsCache -Object $templates -Forever -Identifier "github.secrets_templates.all"
}