# using provider section as a variable as we need to use it in external scripts too.
provider "akamai" {
  edgerc         = "~/.edgerc"
  config_section = var.akamai_config_section
}
