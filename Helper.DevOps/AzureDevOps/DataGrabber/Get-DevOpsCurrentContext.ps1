function Get-DevOpsCurrentContext {

    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'proj')]
        [switch]
        $Project,

        [Parameter(ParameterSetName = 'org')]
        [switch]
        $Organization
    )

    $Context = Get-Content -Path "$PSScriptRoot/.context.current.json" -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue

    if (!$Context) {
        Write-Warning 'No Context Set! Setting Default Context!'
        $Context = Set-DevOpsCurrentContext -Default
    }
    
    if ($Project) {
        return $Context.Project
    }
    elseif ($Organization) {
        return $Context.Organization
    }
}