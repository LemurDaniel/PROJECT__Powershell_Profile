
$values = Get-Content -Path "$PSScriptRoot/resourceNaming.json" | ConvertFrom-Json -Depth 99 -AsHashtable

# Dishing out those Pull-Requests
Invoke-ScriptInAllRepositories `
    -Project 'DC Azure Migration' `
    -workitemTitle 'Naming module should use Terraform Resource names instead of abbreviations' `
    -FilterBlock `
{
    param($Repositories, $Project)  

    $order = @(
        'terraform-acf-main',
        'terraform-acf-adds',
        'terraform-acf-launchpad',
        'terraform-acf-bigipconfig'
    )
    return $Repositories 
    | Where-Object -Property Name -Like 'terraform-*'
    | Sort-Object { $order.IndexOf($_.Name) }
} `
    -ScriptBlock `
{ 
    param($Repository, $Project)  
       
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