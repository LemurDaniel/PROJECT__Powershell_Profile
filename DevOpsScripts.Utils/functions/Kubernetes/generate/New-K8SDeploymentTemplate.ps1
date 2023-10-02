
<#
    .SYNOPSIS
    Interactivley ask user for input to create a deployment template

    .DESCRIPTION
    Interactivley ask user for input to create a deployment template

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS
    The created template for use.

#>

function New-K8SDeploymentTemplate {

    param ()

    $spacing = 5
    $outputTemplates = @()
    $templates = (Get-K8STemplateFiles).templates
    $fragments = (Get-K8STemplateFiles).fragments


    Write-Host -ForegroundColor Magenta "Create a template deployment: "

    $Name = Read-UserInput "Name: " -i $spacing -Required
    $Namespace = Read-UserInput "Namespace: " -i $spacing -Placeholder "None"
    $Selector = Read-UserInput "Selector: " -i $spacing -Placeholder "name: $Name"
    $Namespace = $Namespace -NE 'None' ? "namespace: $Namespace" : ""

    $Service = Read-UserOption "Service: " -i $spacing -Options $("None", "ClusterIP", "LoadBalancer")
    if ($Service -NE 'None') {

        $serviceTemplate = $templates["service"]
        $outputTemplates += $serviceTemplate `
            -replace "\[template_selectors\]", $Selector `
            -replace "\[template_namespace\]", $Namespace `
            -replace "\[template_name\]", $Name `
            -replace "\[template_service\]", $Service
    }


    $Volume = $null
    $VolumeMounts = @()
    do {
        $Volume = Read-UserOption "Volumes: " -i $spacing -Options $("None", "Inline", "PVC") -NoNewLine
        if ($Volume -NE "None") {
            $Options = $fragments['volume'][$Volume]
            $Selected = Read-UserOption -Prompt  "Volumes: " -i $spacing -Options $Options.keys
            $VolumeMounts += $Options[$Selected] `
                -replace "\[fragment_name\]", "mount_name_$($VolumeMounts.Count)"
        }
    } while ($Volume -NE 'None')

    $VolumeMounts = $VolumeMounts -join "`n" 
    $VolumeMounts = $VolumeMounts -split "`n"  
    $VolumeMounts = $VolumeMounts | ForEach-Object { "      $_" }
    $VolumeMounts = $VolumeMounts -join "`n" 

    $outputTemplates += $templates['deployment'] `
        -replace "\[template_selectors\]", $Selector `
        -replace "\[template_namespace\]", $Namespace `
        -replace "\[template_name\]", $Name `
        -replace "\[template_volume_definitions\]", $VolumeMounts



    $generated = $outputTemplates -join "`n---`n"

    $generated | Out-File "test.yaml"
}