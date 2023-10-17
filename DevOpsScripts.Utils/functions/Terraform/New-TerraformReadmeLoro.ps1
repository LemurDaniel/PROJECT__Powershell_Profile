

<#
    .SYNOPSIS
    Automatically create the README-File for a module according to the schema.

    .DESCRIPTION
    Automatically create the README-File for a module according to the schema.

    .INPUTS
    None. You cannot Pipe values into the Function.

    .OUTPUTS
    None

    .LINK
        
#>

function New-TerraformReadmeLoro {

    [CmdletBinding(
        DefaultParameterSetName = "specificModule"
    )]
    param (
        # Folderpath to the target module
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = "specificModule"
        )]
        [ArgumentCompleter(
            {
                param($CommandName, $ParameterName, $WordToComplete)

                $location = (Get-Location).Path
                return Get-ChildItem -Path '*' -File -Recurse -Depth 5 -Filter '*.tf'
                | Select-Object -ExpandProperty Directory
                | Where-Object -Property FullName -NE $location
                | Select-Object -ExpandProperty FullName 
                | Sort-Object | Get-Unique 
                | ForEach-Object {
                    $_.replace($location, '')
                }
                | Where-Object { $_.toLower() -like "*$wordToComplete*".toLower() } 
                | ForEach-Object { $_.contains(' ') ? "'$_'" : $_ } 
            }
        )]
        [System.String]
        $ModulePath,

        # Apply for all on the current path with a limted depth.
        [Parameter(
            Mandatory = $false,
            ParameterSetName = "allOnPath"
        )]
        [switch]
        $AllOnPath,

        # Override existing reamde
        [Parameter(
            Mandatory = $false
        )]
        [switch]
        $Override,

        [Parameter(
            Position = 1,
            Mandatory = $false
        )]
        [System.String[]]
        $BasicVariables = @(
            "location", "environment", "environment_shared", "name_prefix", "company_location", "tags"
        )
    )

    if ($AllOnPath) {

        $location = (Get-Location).Path
        $validValues = Get-ChildItem -Path '*' -File -Recurse -Depth 5 -Filter '*.tf'
        | Select-Object -ExpandProperty Directory
        | Where-Object -Property FullName -NE $location
        | Select-Object -ExpandProperty FullName 
        | Sort-Object | Get-Unique 
        | ForEach-Object {
            $_.replace($location, '')
        }

        foreach ($path in $validValues) {
            Write-Host "Processing Module: $path"
            $null = New-TerraformReadmeLoro -ModulePath $path -BasicVariables $BasicVariables -Override:$Override
        }

        return # End of function for all on path
    }

    function Get-MatchingBrackets {
        param(
            [System.Int32]$startIndex, 
            [System.String]$content, 
            [System.Char]$openingBracket, 
            [System.Char]$closingBracket
        )

        $bracketCount = 0
        $searchString = $content.Substring($startIndex)
        $searchString = $searchString.Substring($searchString.IndexOf($openingBracket))
     
        for ($index = 0; $index -LT $searchString.Length; $index++) {
            if ($searchString[$index] -EQ $openingBracket) {
                $bracketCount++
            }
            elseif ($searchString[$index] -EQ $closingBracket) {
                $bracketCount--;
            }

            if ($bracketCount -EQ 0) {
                return $searchString.Substring(0, $index + 1)
            }
        }
    }

    ###########

    $fullpath = Join-Path -Path (Get-Location).Path -ChildPath $ModulePath
    $directoryInfo = Get-Item -Path $fullpath

    $terraformConfig = @{
        outputs   = @()
        resources = @()
        variables = @()
    }

    foreach ($fileitem in (Get-ChildItem -Path $fullpath -File -Filter "*.tf")) {

        $fileContent = Get-Content -Raw -Path $fileitem.FullName

        if ([System.String]::IsNullOrEmpty($fileContent)) {
            continue
        }

        #######################################################################################
        ### Process Resources
        ###

        foreach ($terraformMatch in [regex]::Matches($fileContent, 'resource\s*"[^"]+"\s*"[^"]+"\s*{')) {

            $terraformConfig['resources'] += @{
                type     = [regex]::Matches($terraformMatch.Value, '"[^"]+"')[0] -replace '"', ''
                name     = [regex]::Matches($terraformMatch.Value, '"[^"]+"')[1] -replace '"', ''
                metaType = 'resources'
            }
            
        }

        foreach ($terraformMatch in [regex]::Matches($fileContent, 'data\s*"[^"]+"\s*"[^"]+"\s*{')) {

            $terraformConfig['resources'] += @{
                type     = [regex]::Matches($terraformMatch.Value, '"[^"]+"')[0] -replace '"', ''
                name     = [regex]::Matches($terraformMatch.Value, '"[^"]+"')[1] -replace '"', ''
                metaType = 'data-sources'
            }
            
        }

        #######################################################################################
        ### Process outputs
        ###

        foreach ($terraformMatch in [regex]::Matches($fileContent, 'output\s*"[^"]+"\s*{')) {

            $blockContent = Get-MatchingBrackets $terraformMatch.Index $fileContent '{' '}'

            $outputName = $terraformMatch.Value -replace 'output|["\s\{]+', ''
            $outputDescription = [regex]::Match($blockContent, 'description\s*=\s*"[^"]+"')
            $outputDescription = [System.String]::IsNullOrEmpty($outputDescription) ? "(undefined)" : $outputDescription.Value
            $outputDescription = $outputDescription -replace 'description\s*=\s*"', '' -replace '"', ''

            $terraformConfig['outputs'] += @{
                name        = $outputName.Trim()
                description = $outputDescription.Trim()
            }
        }

        #######################################################################################
        ### Process variables
        ###

        foreach ($terraformMatch in [regex]::Matches($fileContent, 'variable\s*"[^"]+"\s*{')) {

            $blockContent = Get-MatchingBrackets $terraformMatch.Index $fileContent '{' '}'

            $variableName = $terraformMatch.Value -replace 'variable|["\s\{]+', ''
            $variableDescription = [regex]::Match($blockContent, 'description\s*=\s*"[^"]+"')
            $variableRequired = 'undefined'
        
            $variableDescription = [System.String]::IsNullOrEmpty($variableDescription) ? "(undefined)" : $variableDescription.Value
            $variableDescription = $variableDescription -replace 'description\s*=\s*"', '' -replace '"', ''
            if ($variableDescription.toLower().contains('required')) {
                $variableRequired = "Required"
            }
            elseif ($variableDescription.toLower().contains('optional')) {
                $variableRequired = "Optional"
            }
            $variableDescription = $variableDescription -replace '\(required\)|\(optional\)', ''


            $variableType = [regex]::Match($blockContent, 'type\s*=\s*[^\n]+')
            if ([System.String]::IsNullOrEmpty($variableType)) {
                $variableType = '(undefined)'
            }
            elseif ($variableType.Value.Contains('(')) {
                $temporary = [regex]::match($variableType.Value, "=.*\(") -replace '[=\s\(]', ''
                $variableTypeBracketContent = Get-MatchingBrackets -startIndex ($variableType.Index) $blockContent '(' ')'
                $variableType = ($temporary + $variableTypeBracketContent) -replace '\s', ''
            }
        


            $variableType = $variableType -replace 'type\s*=\s*|`n|#+.*', ''
            if ($variableType.toLower().contains('object')) {
                $variableType = 'Complex Object'
            }
        
            $terraformConfig['variables'] += @{
                name        = $variableName.Trim()
                type        = $variableType.Trim()
                description = $variableDescription.Trim()
                required    = $variableRequired.Trim()
            }
            
        }

    }

    #######################################################################################
    ### Generate Readme file from data
    ###

    # Process existing module description
    $moduleDescription = $null
    $existingReadme = Get-ChildItem -Path $fullpath -File -Filter "README.md" # Is case-insensitive
    if ($null -NE $existingReadme) {

        $readmeContent = Get-Content -Raw -Path $existingReadme.FullName
        $descriptionMatch = [regex]::Match($readmeContent, '<h\d>[Dd]escription<\/h\d>')

        if ($descriptionMatch) {
            $descriptionContent = $readmeContent.Substring($descriptionMatch.Index + $descriptionMatch.Value.Length)
            $descriptionContent = [regex]::Match($descriptionContent, '[\s\S]*?<h\d>').Value -replace '<h\d>', ''
            $moduleDescription = $descriptionContent.Trim()
        }
    }

    $resourceMarkdown = $terraformConfig['resources']
    | ForEach-Object {
        # TODO Works only for official hashicorp providers.
        $providerName = $_.type.split('_')[0]
        $resourceName = $_.type.replace($providerName, '').Substring(1)
        
        $providerInfo = Get-TerraformProviderInfo -provider "hashicorp/$providerName"
        $resourceInfo = $providerInfo
        | Select-Object -ExpandProperty docs
        | Where-Object -Property category -like $_.metaType
        | Where-Object {
            $_.slug -like $resourceName -OR $_.title -like $resourceName
        }

        $documentationUrl = "https://registry.terraform.io/providers/{{namespace}}/{{provider}}/{{version}}/docs/{{category}}/{{resource}}"
        $documentationUrl = $documentationUrl.replace('{{namespace}}', 'hashicorp')
        $documentationUrl = $documentationUrl.replace('{{provider}}', $providerInfo.name)
        $documentationUrl = $documentationUrl.replace('{{version}}', 'latest')
        $documentationUrl = $documentationUrl.replace('{{category}}', $resourceInfo.category)
        $documentationUrl = $documentationUrl.replace('{{resource}}',
         ([System.String]::IsNullOrEmpty($resourceInfo.slug) ? $resourceInfo.title : $resourceInfo.slug)
        )

        @(
            "    <tr>",
            "        <td>$($_.metaType)</td>",
            "        <td>",
            "            <a href=`"$documentationUrl`">$($_.type)</a>",
            "        </td>",
            "        <td>$($_.name)</td>",
            "    </tr>"
        ) -join [System.Environment]::NewLine
    }

    $basicVariablesMarkdown = $terraformConfig['variables']
    | Where-Object -Property name -in $BasicVariables
    | ForEach-Object {
        @(
            "    <tr>",
            "        <td>$($_.name)</td>",
            "        <td>$($_.type)</td>",
            "        <td>$($_.required)</td>",
            "        <td>$($_.description)</td>",
            "    </tr>"
        ) -join [System.Environment]::NewLine
    }

    $moduleVariablesMarkdown = $terraformConfig['variables']
    | Where-Object -Property name -notin $BasicVariables
    | ForEach-Object {
        @(
            "    <tr>",
            "        <td>$($_.name)</td>",
            "        <td>$($_.type)</td>",
            "        <td>$($_.required)</td>",
            "        <td>$($_.description)</td>",
            "    </tr>"
        ) -join [System.Environment]::NewLine
    }

    $moduleOutputsMarkdown = $terraformConfig['outputs']
    | Where-Object -Property name -notin $BasicVariables
    | ForEach-Object {
        @(
            "    <tr>",
            "        <td>$($_.name)</td>",
            "        <td>$($_.description)</td>",
            "    </tr>"
        ) -join [System.Environment]::NewLine
    }

    $ReadmeMarkdown = @"
<h1>$($directoryInfo.BaseName)-Module</h1>


<h2>Description</h2>

$(
    if($null -NE $moduleDescription) {
        $moduleDescription
    } else {
        @(
        "<p>"
        ""
        "("
        "    ...The human input part of writing a description"
        ")"
        ""
        "</p>"
        ) -join [System.Environment]::NewLine
    }
)

<h2>Resources</h2>

<table>
    <tr>
        <th>Resource Meta Type</th>
        <th>Resource Provider Type</th>
        <th>Resource Name</th>
    </tr>
    $($resourceMarkdown -Join [System.Environment]::NewLine)
</table>



<h2>Variables</h2>

<h4>Basic variables</h4>

<table>
    <tr>
        <th>Name</th>
        <th>Type</th>
        <th>Required</th>
        <th>Description</th>
    </tr>
    $($basicVariablesMarkdown -Join [System.Environment]::NewLine)
</table>


<h4>Module variables</h4>

<table>
    <tr>
        <th>Name</th>
        <th>Type</th>
        <th>Required</th>
        <th>Description</th>
    </tr>
    $($moduleVariablesMarkdown -Join [System.Environment]::NewLine)
</table>



<h2>Outputs</h2>

<h4>Module outputs</h4>

<table>
    <tr>
        <th>Name</th>
        <th>Description</th>
    </tr>
    $($moduleOutputsMarkdown -Join [System.Environment]::NewLine)
</table>
"@

    if ($Override) {
        if ($existingReadme) {
            Remove-Item -Path $existingReadme.FullName
        }
        $ReadmeMarkdown | Out-File -FilePath "$fullpath/README.md"
    }
    else {
        $ReadmeMarkdown | Out-File -FilePath "$fullpath/README.generated.md"
    }

    return $terraformConfig
}