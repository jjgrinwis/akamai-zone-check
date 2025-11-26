variable "akamai_config_section" {
  description = "The Akamai CLI config section to use"
  type        = string
  default     = "gss-tc-east"

}
variable "hostname" {
  description = "The full hostname to process (e.g., a.test.example.com)"
  type        = string
}
