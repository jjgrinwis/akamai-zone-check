terraform {
  required_providers {
    akamai = {
      source  = "akamai/akamai"
      version = ">=9.2.0" # CCM requires akamai provider version 9.2.0 and above
    }
  }
  required_version = ">= 1.2.0" # preconditions requires Terraform 1.2.0 and above
}
