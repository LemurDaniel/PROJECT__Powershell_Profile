function Get-OneDriveItems {

    [CmdletBinding()]  
    param (
        [Parameter(ValueFromPipeline)] 
        $1driveFiles 
    )
    Begin {
  
        $byteArray = (1..32 | ForEach-Object { [byte](Get-Random -Max 256) })
        $randomString = [System.Convert]::ToHexString(($byteArray))
        $Outpath = "C:$env:HOMEPATH\downloads\$randomString"

        $directory = New-Item -Path $Outpath -ItemType Directory

    }
    Process {
    
        $accessToken = Update-OneDriveToken
        foreach ($item in $1driveFiles) {
            $null = Get-ODItem -AccessToken $accessToken `
                -ElementId $item.id -LocalPath $Outpath -LocalFileName $item.name
        }

    }
    End {
        return Get-ChildItem -Path $directory.FullName
    }
}