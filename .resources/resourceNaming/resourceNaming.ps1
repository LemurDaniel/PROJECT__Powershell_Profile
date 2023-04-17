
$values = Get-Content -Path "$PSScriptRoot/resourceNaming.json" | ConvertFrom-Json -Depth 99 -AsHashtable

$orderedLast = @(
    'terraform-acf-main',
    'terraform-acf-adds',
    'terraform-acf-launchpad',
    'terraform-acf-bigipconfig'
)
(Get-ProjectInfo -Name 'DC Azure Migration').repositories
| Where-Object -Property Name -Like 'terraform-*'
| Sort-Object { $orderedLast.IndexOf($_.Name) } 
| Invoke-ScriptInRepositories `
    -workitemTitle 'Naming module should use Terraform Resource names instead of abbreviations' `
    -ScriptBlock `
{ 
    param($Repository, $Project)  
       
    Write-Host $Repository.Name
    return
    Update-ModuleSourcesInPath -replacementPath $Repository.Localpath -Confirm:$false
    $values.GetEnumerator() | ForEach-Object {

        $config = @{
            Filter          = '*.tf'
            Confirm         = $false
            replacementPath = $Repository.Localpath
            regexQuery      = "type\s+=\s+`"$($_.Key)`""
            replace         = "type = `"$($_.Value)`""
            postScript      = {
                param($File)
                terraform fmt $file.Fullname
            }
        }
        Edit-RegexOnFiles @config
    }
}