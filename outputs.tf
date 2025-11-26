output "zone_detection" {
  value = {
    hostname             = var.hostname
    specific_zone        = local.specific_zone
    parent_zone          = local.parent_zone
    specific_zone_exists = local.specific_zone_exists
    parent_zone_exists   = local.parent_zone_exists
    selected_zone        = local.selected_zone
    record_name          = local.record_name
  }
  description = "Zone detection results and selected configuration"
}
