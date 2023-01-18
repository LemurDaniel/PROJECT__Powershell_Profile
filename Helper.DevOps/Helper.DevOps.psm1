

class HTTPMethods : System.Management.Automation.IValidateSetValuesGenerator {

    [String[]] GetValidValues() {
        return [System.Net.Http.HttpMethod].GetProperties().Name
    }

}

enum SecretScope {
    ALL
    ORG
    PERSONAL
}

@(
    'PatLifeCycle',
	'SecretStore',
    'AzureDevOps',
    'VersionControl'
) | `
    ForEach-Object { Get-Item "$PSScriptRoot/$_" } | `
    Get-ChildItem -Recurse -Filter '*.ps1' -ErrorAction Stop | `
    ForEach-Object { . $_.FullName }