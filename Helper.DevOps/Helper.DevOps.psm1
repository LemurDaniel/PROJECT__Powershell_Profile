


@(
    'PatLifeCycle',
    'SecretStore',
    'AzureDevOps',
    'VersionControl',
    'Github'
) | `
    ForEach-Object { Get-Item "$PSScriptRoot/$_" } | `
    Get-ChildItem -Recurse -Filter '*.ps1' -File -ErrorAction Stop | `
    ForEach-Object { . $_.FullName }