
<#
    .SYNOPSIS
    Interactivley ask user for input to create a ingress template

    .DESCRIPTION
    Interactivley ask user for input to create a ingress template

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS
    The created template for use.

#>

function New-K8SIngress {

    param ()

    $spacing = 5
    $outputTemplates = @()
    $templates = (Get-K8STemplateFiles).templates
    $fragments = (Get-K8STemplateFiles).fragments


    Write-Host -ForegroundColor Magenta "Create a template ingress: "

    $Name = Read-UserInput "Name: " -i $spacing -Required
    $Namespace = Read-UserInput "Namespace: " -i $spacing -Placeholder "None"
    $Namespace = $Namespace -NE 'None' ? "namespace: $Namespace" : ""

    $ingressTemplates = $templates['ingress']
    $selectedIngress = Read-UserOption "Type: " -i $spacing -Options $ingressTemplates.Keys

    $outputTemplates += $ingressTemplates[$selectedIngress] `
        -replace "\[template_namespace\]", $Namespace `
        -replace "\[template_name\]", $Name 



    $generated = $outputTemplates -join "`n---`n"

    $generated | Out-File "test.ingress.yaml"
}