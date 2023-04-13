config {
  force = false

  ignore_module = {}
}

plugin "terraform" {
  enabled = true
}

rule "terraform_unused_required_providers" {
  enabled = false
}

rule "terraform_required_providers" {
  enabled = false
}

rule "terraform_required_version" {
  enabled = false
}

plugin "azurerm" {
    enabled = true
    version = "0.22.0"
    source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}