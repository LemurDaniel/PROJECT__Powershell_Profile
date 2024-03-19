#
# Module manifest for module 'DevOpsScripts.Utils'
#
# Generated by: o.O
#
# Generated on: 03/19/2024
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'DevOpsScripts.Utils.psm1'

# Version number of this module.
ModuleVersion = '1.0.2'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '38996dc6-d6e5-479e-bc30-c8f103778863'

# Author of this module
Author = 'o.O'

# Company or vendor of this module
CompanyName = 'Unknown'

# Copyright statement for this module
Copyright = '(c) o.O. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Provides several utility-function like chaching to JSON-Files, etc.'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '7.2'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'Get-Property', 'Join-PsObject', 'Search-In', 
               'Clear-SecureStringFromFile', 'Clear-UtilsCache', 'Get-CleanFilename', 
               'Get-UtilsCache', 'Get-UtilsCachePath', 'Get-UtilsConfiguration', 
               'Open-SecureStringFolder', 'Open-UtilsCacheFolder', 
               'Read-SecureStringFromFile', 'Save-SecureStringToFile', 
               'Set-UtilsCache', 'Set-UtilsConfiguration', 'Format-SendGridContent', 
               'Format-SendGridResourceReport', 'Send-SendGridEmail', 
               'New-SendGridHtmlFormat', 'Convert-TFVarsToObject', 
               'Get-TerraformProviderInfo', 'Get-TerraformProviders', 
               'Get-TerraformVersions', 'New-TerraformReadmeLoro', 
               'Open-TerraformProviderDocs', 'Remove-MovedBlocks', 
               'Remove-TerraformState', 'Set-Terraform', 'Get-AzureadResources', 
               'Get-AzureResourceTypes', 'Get-AzurermResources', 
               'Get-KubernetesResources', 'Get-ProviderResources', 
               'Get-TerraformAzuremMapping', 'Get-TerraformModuleCalls', 
               'Get-TerraformModuleCallsOld', 'Get-TerraformModuleResources', 
               'New-TerraformAzureImportStatement', 'Invoke-AutoCompleterFileName', 
               'Get-K8SClusterResources', 'Get-K8SContexts', 
               'Get-K8SKindPropertyTree', 'Get-K8SResourceKind', 'Get-K8SResources', 
               'Invoke-K8SExec', 'Read-K8SLogs', 'Remove-K8SContext', 
               'Select-K8SLabels', 'Select-K8SResource', 'Show-K8SExplanation', 
               'Show-K8SResource', 'Switch-K8SCluster', 'Switch-K8SNamespace', 
               'Get-K8STemplateFiles', 'New-K8SDeployment', 'New-K8SIngress', 
               'Add-CodeEditor', 'Add-ConsoleTestImages', 'Clear-CodeEditor', 
               'Edit-RegexOnFiles', 'Get-CodeEditor', 'Get-ConsoleTestImages', 
               'Remove-InvisibleUnicode', 'Switch-DefaultCodeEditor', 
               'Test-IsRepository', 'ConvertTo-RGB', 'Get-ANSIEscapeSequences', 
               'New-ANSIEscapeCode', 'New-RandomBytes', 'Open-InCodeEditor', 
               'Read-UserInput', 'Read-UserOption', 'Select-ConsoleMenu', 
               'Show-ConsoleImage', 'Start-LoadingBarAnimation', 
               'Start-LoadingCircleAnimation'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
# VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = 'Select-Property', 'property', 'get', 'Search-PreferencedObject', 
               'Search', 'tfDocs', 'staterm', 'tf', 'tf-import', 'k8s-exec', 'k8s-logs', 
               'k8s-explain', 'k8s-expl', 'k8s-describe', 'k8s-cluster', 'k8s-ns'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        # ProjectUri = ''

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

