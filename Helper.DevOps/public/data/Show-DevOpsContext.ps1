
function Show-DevOpsContext {

    [CmdletBinding()]
    param ()

    $Organization = Get-DevOpsCurrentContext -Organization
    $Project = Get-DevOpsCurrentContext -Project
     
    Write-Host -ForegroundColor GREEN "`nCurrent Context:"
    Write-Host -ForegroundColor GREEN "     Organization: $Organization "
    Write-Host -ForegroundColor GREEN "     Project:      $Project"
    Write-Host
}