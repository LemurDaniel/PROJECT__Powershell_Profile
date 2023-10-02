
<#
    .SYNOPSIS
    Returns templates files and fragmens as a hastable.

    .DESCRIPTION
    Returns templates files and fragmens as a hastable.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS
    The template files and fragments as a hashtable.

#>

function Get-K8STemplateFiles {

    param()

    $templates = [System.Collections.Hashtable]::new()
    $fragments = [System.Collections.Hashtable]::new()
    $path = "C:\Users\dlandau\git\repos\GITHUB\LemurDaniel\LemurDaniel\PROJECT__Powershell_Profile\DevOpsScripts.Utils\functions\Kubernetes\generate"
 
    Get-ChildItem -Path "$path/fragments" 
    | ForEach-Object {
        $hashtable = $fragments
        $segments = $_.BaseName.split('.')
        for ($index = 0; $index -LT $segments.Count; $index++) {

            $segment = $segments[$index]
            if ($index -EQ $segments.Count - 1) {
                $content = Get-Content -Raw -Path $_.FullName
                $null = $hashtable.Add($segment, $content)
            }
            else {
                $null = $hashtable.Add($segment, @{})
                $hashtable = $hashtable[$segment]
            }
        }
    }

    Get-ChildItem -Path "$path/templates" 
    | ForEach-Object {
        $hashtable = $templates
        $segments = $_.BaseName.split('.')
        for ($index = 0; $index -LT $segments.Count; $index++) {

            $segment = $segments[$index]
            if ($index -EQ $segments.Count - 1) {
                $content = Get-Content -Raw -Path $_.FullName
                $null = $hashtable.Add($segment, $content)
            }
            else {
                $null = $hashtable.Add($segment, @{})
                $hashtable = $hashtable[$segment]
            }
        }
    }

    return @{
        templates = $templates
        fragments = $fragments
    }
}