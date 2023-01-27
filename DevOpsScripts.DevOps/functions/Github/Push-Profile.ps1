function Push-Profile {

    param()

    $fileItem = Open-RepositoryGithub -Name 'PROJECT__Powershell_Profile' -noCode

    Switch-GitConfig -config GIT

    if ($fileItem) {
        $byteArray = (1..4 | ForEach-Object { [byte](Get-Random -Max 256) })
        $hex = [System.Convert]::ToHexString($byteArray)

        git -C $fileItem.FullName pull origin
        git -C $fileItem.FullName add -A
        git -C $fileItem.FullName commit -S -m "$hex"
        git -C $fileItem.FullName push

    }

    $byteArray = (1..4 | ForEach-Object { [byte](Get-Random -Max 256) })
    $hex = [Convert]::ToHexString($byteArray)

    git -C "$PSScriptRoot/../.." pull origin
    git -C "$PSScriptRoot/../.." add -A
    git -C "$PSScriptRoot/../.." commit -S -m "$hex"
    git -C "$PSScriptRoot/../.." push

    Switch-GitConfig -config ($env:USERNAME -eq 'M01947' ? 'brz' : 'git')
}