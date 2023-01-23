


@(
    'RestApi',
    'ResourceGraph',
    'GraphApi',
    'General',
    'Authorization'
) | `
    ForEach-Object { Get-Item "$PSScriptRoot/$_" } | `
    Get-ChildItem -Recurse -Filter '*.ps1' -ErrorAction Stop | `
    ForEach-Object { . $_.FullName }