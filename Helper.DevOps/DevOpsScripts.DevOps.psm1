

@(
    'AzureDevOps',
    'PatLifeCycle'
) | `
    ForEach-Object { Get-Item "$PSScriptRoot/$_" } | `
    Get-ChildItem -Filter '*.ps1' -ErrorAction Stop | `
    ForEach-Object { . $_.FullName }