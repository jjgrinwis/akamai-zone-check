locals {
  # Split the hostname into parts
  hostname_parts = split(".", var.hostname)

  # Validate hostname has enough parts (at least domain.tld)
  hostname_valid = length(local.hostname_parts) >= 2

  # Calculate potential zone names
  # For a.test.example.com: test.example.com (skip first part)
  specific_zone = local.hostname_valid && length(local.hostname_parts) > 2 ? join(".", slice(local.hostname_parts, 1, length(local.hostname_parts))) : null

  # For a.test.example.com: example.com (last two parts)
  parent_zone = local.hostname_valid ? join(".", slice(local.hostname_parts, length(local.hostname_parts) - 2, length(local.hostname_parts))) : null

  # Determine which zone exists and should be used
  specific_zone_exists = local.specific_zone != null && try(data.external.specific_zone_check[0].result.exists == "true", false)
  parent_zone_exists   = local.parent_zone != null && try(data.external.parent_zone_check[0].result.exists == "true", false)

  # Select the most specific zone that exists
  selected_zone = local.specific_zone_exists ? local.specific_zone : (local.parent_zone_exists ? local.parent_zone : null)

  # Calculate the record name relative to the selected zone
  # For hostname "a.test.example.com" in zone "test.example.com": record is "a"
  # For hostname "a.test.example.com" in zone "example.com": record is "a.test"
  zone_parts  = local.selected_zone != null ? split(".", local.selected_zone) : []
  record_name = local.selected_zone != null ? join(".", slice(local.hostname_parts, 0, length(local.hostname_parts) - length(local.zone_parts))) : var.hostname
}

# Validation: ensure we found a zone
resource "null_resource" "zone_validation" {
  count = local.selected_zone == null ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'ERROR: No valid Akamai DNS zone found for hostname ${var.hostname}' >&2 && exit 1"
  }
}


# Check if specific zone exists (only if we have one to check)
data "external" "specific_zone_check" {
  count = local.specific_zone != null ? 1 : 0

  program = ["bash", "-c", <<-EOF
    set -e
    zone="$1"
    section="$2"
    
    # Exit with error if zone parameter is empty
    if [ -z "$zone" ]; then
      echo '{"exists":"false","error":"empty_zone"}' >&2
      exit 1
    fi
    
    # Check if zone exists using the same section as the provider
    if akamai --section "$section" dns retrieve-zoneconfig "$zone" >/dev/null 2>&1; then
      echo "{\"exists\":\"true\",\"zone\":\"$zone\"}"
    else
      echo "{\"exists\":\"false\",\"zone\":\"$zone\"}"
    fi
  EOF
  , "--", local.specific_zone, var.akamai_config_section]
}

# Check parent zone as fallback
data "external" "parent_zone_check" {
  # Only check parent if specific zone doesn't exist or isn't available
  count = local.parent_zone != null && (local.specific_zone == null || try(data.external.specific_zone_check[0].result.exists != "true", true)) ? 1 : 0

  program = ["bash", "-c", <<-EOF
    set -e
    zone="$1"
    section="$2"
    
    if [ -z "$zone" ]; then
      echo '{"exists":"false","error":"empty_zone"}' >&2
      exit 1
    fi
    
    # Check if zone exists using the same section as the provider
    if akamai --section "$section" dns retrieve-zoneconfig "$zone" >/dev/null 2>&1; then
      echo "{\"exists\":\"true\",\"zone\":\"$zone\"}"
    else
      echo "{\"exists\":\"false\",\"zone\":\"$zone\"}"
    fi
  EOF
  , "--", local.parent_zone, var.akamai_config_section]
}
