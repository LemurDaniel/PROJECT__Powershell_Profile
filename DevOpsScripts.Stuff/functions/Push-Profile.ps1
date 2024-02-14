function Push-Profile {

    param()

    $fileItem = Open-GitRepository -Account 'LemurDaniel' -Context 'LemurDaniel' -Name 'PROJECT__Powershell_Profile' -onlyDownload

    $gitUser = Get-GitUser -Account 'LemurDaniel'

    if ($fileItem) {
        $byteArray = (1..4 | ForEach-Object { [byte](Get-Random -Max 256) })
        $hex = [System.Convert]::ToHexString($byteArray)

        git -C $fileItem.FullName  config --local user.email $gitUser.email
        git -C $fileItem.FullName  config --local user.name $gitUser.login
        git -C $fileItem.FullName  config --local commit.gpgsign true

        git -C $fileItem.FullName pull origin
        git -C $fileItem.FullName add -A
        git -C $fileItem.FullName commit -S -m "$hex"
        git -C $fileItem.FullName push

    }

    $byteArray = (1..4 | ForEach-Object { [byte](Get-Random -Max 256) })
    $hex = [Convert]::ToHexString($byteArray)

    git -C "$PSScriptRoot/../.." config --local user.email $gitUser.email
    git -C "$PSScriptRoot/../.." config --local user.name $gitUser.login
    git -C "$PSScriptRoot/../.." config --local commit.gpgsign true

    git -C "$PSScriptRoot/../.." pull origin
    git -C "$PSScriptRoot/../.." add -A
    git -C "$PSScriptRoot/../.." commit -S -m "$hex"
    git -C "$PSScriptRoot/../.." push

}