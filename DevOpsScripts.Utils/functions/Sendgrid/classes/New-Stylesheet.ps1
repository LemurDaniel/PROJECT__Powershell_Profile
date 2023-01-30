class Stylesheet : System.Management.Automation.IValidateSetValuesGenerator {

    static [System.IO.DirectoryInfo] GetCssFolder() {
        $folder = [System.String]::IsNullOrEmpty($PSScriptRoot) ? (Get-Location) : "$PSScriptRoot/../"
        return Get-ChildItem -Path "$folder" -Recurse -Directory -Filter 'css'
    }

    static [System.IO.FileInfo[]] GetCssFiles() {
        return Get-ChildItem -Path ([Stylesheet]::GetCssFolder()) -Filter '*.css'
    }

    static [System.String] GetCSSContentTargetedToId($FileName, $id) {
        $stylesheetContent = [Stylesheet]::GetCssFiles() | Where-Object -Property BaseName -EQ -Value $FileName | Get-Content -Raw
        return $stylesheetContent -replace '#id', "#$id"
        #return ([regex]::Matches($stylesheetContent, '([a-zA-Z][^{]*\{[^}]*\})') | ForEach-Object { "#$id $($_.Value)" }) -join ' '
    }

    [String[]] GetValidValues() {
        return @($null, '') + [Stylesheet]::GetCssFiles().BaseName
    }
}
  

function New-Stylesheet {

    [CmdletBinding()]
    param ()

    return [Stylesheet]::new()
    
}