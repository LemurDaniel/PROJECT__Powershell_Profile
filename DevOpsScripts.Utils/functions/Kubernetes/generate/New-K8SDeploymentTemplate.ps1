


# Function for quickly creating templates to expand on.

function New-K8SDeploymentTemplate {

    param ()


    $path = "C:\Users\Daniel\git\repos\GITHUB\LemurDaniel\LemurDaniel\PROJECT__Powershell_Profile\DevOpsScripts.Utils\functions\Kubernetes\generate"
    
    $templates = "$path/templates"
    $fragments = "$path/fragments"



    $outputTemplates = @()
    Write-Host -ForegroundColor Magenta "Create a template deployment: "

    $Name = Read-UserInput -Prompt      "   Name: "  -Required
    $Namespace = Read-UserInput -Prompt "   Namespace: " -Placeholder "None"
    $Selector = Read-UserInput -Prompt  "   Selector: " -Placeholder "name: $Name"
    $Namespace = $Namespace -NE 'None' ? "namespace: $Namespace" : ""

    $Service = Read-UserOption -Prompt  "   Service: " -Options $("None", "ClusterIP", "LoadBalancer")
    if ($Service -NE 'None') {

        $serviceTemplate = Get-Content -Raw -Path "$templates/service.template.yaml"
        $outputTemplates += $serviceTemplate `
            -replace "\[template_selectors\]", $Selector `
            -replace "\[template_namespace\]", $Namespace `
            -replace "\[template_name\]", $Name `
            -replace "\[template_service\]", $Service
    }


    $Volume = $null
    $VolumeMounts = @()
    do {
        $Volume = Read-UserOption -Prompt  "   Volumes: " -Options $("None", "Inline", "PVC") -NoNewLine
        if ($Volume -NE "None") {
            $Options = Get-ChildItem -Path "$fragments" -Filter "volume.$Volume.*"
            $Template = Read-UserOption -Prompt  "   Volumes: " -Options $Options.BaseName.split('.')[-1]
            $Template = Get-Content -Raw -Path "$fragments/volume.$Volume.$Template.yaml"

            $VolumeMounts += $Template -replace "\[fragment_name\]", "mount_name_$($VolumeMounts.Count)"
        }
    } while ($Volume -NE 'None')
    $VolumeMounts = $VolumeMounts -join "`n" 
    $VolumeMounts = $VolumeMounts -split "`n"  
    $VolumeMounts = $VolumeMounts | ForEach-Object { "      $_" }
    $VolumeMounts = $VolumeMounts -join "`n" 

    $deploymentTemplate = Get-Content -Raw -Path "$templates/deployment.template.yaml"
    $outputTemplates += $deploymentTemplate `
        -replace "\[template_selectors\]", $Selector `
        -replace "\[template_namespace\]", $Namespace `
        -replace "\[template_name\]", $Name `
        -replace "\[template_volume_definitions\]", $VolumeMounts



    $generated = $outputTemplates -join "`n---`n"

    $generated | Out-File "test.yaml"
}