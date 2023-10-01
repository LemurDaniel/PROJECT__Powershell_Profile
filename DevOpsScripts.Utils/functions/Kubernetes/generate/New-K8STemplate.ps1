





function New-K8STemplate {

    param (
        [Parameter(
            Mandatory = $true
        )]
        [ArgumentCompleter(
            {
                param($cmd, $param, $wordToComplete, $commandAst, $fakeBoundParameters)
                
                $path = "C:\Users\Daniel\git\repos\GITHUB\LemurDaniel\LemurDaniel\PROJECT__Powershell_Profile\DevOpsScripts.Utils\functions\Kubernetes\template.json"
            
                $validValues = (Get-ChildItem -Path $path | ConvertFrom-Json -AsHashtable).Keys

                $validValues 
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        $Kind
    )
    
}