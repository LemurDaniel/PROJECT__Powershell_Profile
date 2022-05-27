class PsProfile : System.Management.Automation.IValidateSetValuesGenerator {
  [String[]] GetValidValues() {
    return @(
      "Profile",
      "All"
    ) + (Get-ChildItem -Path $env:PROFILE_HELPERS_PATH -Filter "*.ps1").Name.replace('.ps1', '')
  }
}

class RepoProjects : System.Management.Automation.IValidateSetValuesGenerator {
  [String[]] GetValidValues() {
    return  ((Get-ChildItem -Path $env:RepoPath -Filter "_*").Name | `
        Select-String -Pattern "^_[A-Z]*[-]{0,1}").Matches.Value.Replace('_', '').Replace('-', '')
  }
}



