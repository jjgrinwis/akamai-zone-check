variable "hostname" {
  description = "The full hostname to process (e.g., a.test.example.com)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)+$", var.hostname))
    error_message = "The hostname must be a valid FQDN (e.g., a.test.example.com)."
  }

  validation {
    condition     = length(split(".", var.hostname)) >= 2
    error_message = "The hostname must have at least a domain and TLD (e.g., example.com)."
  }
}

variable "akamai_config_section" {
  description = "The Akamai CLI config section to use from ~/.edgerc"
  type        = string
  default     = "default"

  validation {
    condition     = length(var.akamai_config_section) > 0
    error_message = "The akamai_config_section cannot be empty."
  }
}

variable "edgerc_path" {
  description = "Path to the Akamai .edgerc file"
  type        = string
  default     = "~/.edgerc"

  validation {
    condition     = length(var.edgerc_path) > 0
    error_message = "The edgerc_path cannot be empty."
  }
}
