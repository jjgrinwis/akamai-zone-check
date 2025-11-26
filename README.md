# Akamai EdgeDNS Zone Detection

A Terraform module that intelligently detects which DNS zone to use in Akamai EdgeDNS based on a fully qualified hostname.

## Problem Statement

When working with DNS records in Akamai EdgeDNS, you might have a hostname like `a.test.example.com` and need to determine whether the zone `test.example.com` exists, or if you should use the parent zone `example.com` instead.

This module automatically:

1. Checks if a more specific zone exists (e.g., `test.example.com`)
2. Falls back to the parent zone if the specific zone doesn't exist (e.g., `example.com`)
3. Calculates the correct record name relative to the selected zone

## How It Works

Given a hostname like `a.test.example.com`, the module:

1. **Splits the hostname** into parts: `["a", "test", "example", "com"]`
2. **Identifies potential zones:**
   - Specific zone: `test.example.com` (all parts except the first)
   - Parent zone: `example.com` (last two parts)
3. **Checks zone existence** using the Akamai CLI command `akamai dns retrieve-zoneconfig`
4. **Selects the appropriate zone:**
   - If `test.example.com` exists → uses `test.example.com`, record name is `a`
   - If only `example.com` exists → uses `example.com`, record name is `a.test`
5. **Validates** that at least one zone exists, failing if neither is found

## Prerequisites

- Terraform >= 1.2.0
- Akamai Provider >= 9.2.0
- [Akamai CLI](https://github.com/akamai/cli) installed and configured
- Valid `~/.edgerc` file with appropriate credentials

## Usage

### Basic Example

```hcl
module "zone_check" {
  source = "./akamai-zone-check"

  hostname = "a.test.example.com"
}

# Use the detected zone in your DNS resources
resource "akamai_dns_record" "example" {
  zone        = module.zone_check.zone_detection.selected_zone
  name        = module.zone_check.zone_detection.record_name
  recordtype  = "A"
  ttl         = 300
  target      = ["192.0.2.1"]
}
```

### Custom Akamai Config Section

```hcl
module "zone_check" {
  source = "./akamai-zone-check"

  hostname               = "www.mysite.com"
  akamai_config_section  = "production"
}
```

## Inputs

| Name                  | Description                                             | Type   | Default       | Required |
| --------------------- | ------------------------------------------------------- | ------ | ------------- | -------- |
| hostname              | The full hostname to process (e.g., a.test.example.com) | string | n/a           | yes      |
| akamai_config_section | The Akamai CLI config section to use                    | string | "gss-tc-east" | no       |

## Outputs

The module provides a single `zone_detection` output containing:

```hcl
{
  hostname             = "a.test.example.com"
  specific_zone        = "test.example.com"      # The more specific zone attempted
  parent_zone          = "example.com"           # The parent zone (fallback)
  specific_zone_exists = false                   # Whether specific zone exists
  parent_zone_exists   = true                    # Whether parent zone exists
  selected_zone        = "example.com"           # The zone that was selected
  record_name          = "a.test"                # The record name relative to selected zone
}
```

## Examples

### Scenario 1: Specific Zone Exists

**Input:** `hostname = "www.staging.example.com"`

- If `staging.example.com` exists in Akamai EdgeDNS:
  - `selected_zone = "staging.example.com"`
  - `record_name = "www"`

### Scenario 2: Only Parent Zone Exists

**Input:** `hostname = "app.dev.example.com"`

- If `dev.example.com` doesn't exist but `example.com` does:
  - `selected_zone = "example.com"`
  - `record_name = "app.dev"`

### Scenario 3: Simple Hostname

**Input:** `hostname = "www.example.com"`

- Only checks parent zone `example.com`:
  - `selected_zone = "example.com"`
  - `record_name = "www"`

## Implementation Details

This module uses Terraform's `external` data source to execute Akamai CLI commands. This approach was chosen because:

1. The Akamai Terraform provider doesn't provide a data source for zone lookups
2. Data sources in Terraform fail hard on errors with no way to catch them gracefully
3. The `external` data source allows graceful error handling

The inline bash script checks zone existence by attempting to retrieve the zone configuration. If successful, the zone exists; otherwise, it doesn't.

## Limitations

- Assumes zones follow the pattern of either `subdomain.domain.tld` or `domain.tld`
- Requires the Akamai CLI to be installed and properly configured
- The `akamai_config_section` must have permissions to read DNS zones
- Network connectivity to Akamai APIs is required during `terraform plan`

## Testing

```bash
# Initialize Terraform
terraform init

# Test with different hostnames
echo 'hostname = "a.test.example.com"' > terraform.tfvars
terraform plan

# View the zone detection results
terraform apply
terraform output zone_detection
```

## License

This project is provided as-is for use with Akamai EdgeDNS configurations.
