function Get-BlenderFiles {

    [CmdletBinding()]
    param ()

    return @(
        "$env:OneDrive/3D",
        "$env:OneDrive/_Shared/Blender"
    ) | Get-ChildItem -Recurse -File -Filter "*.blend"


}