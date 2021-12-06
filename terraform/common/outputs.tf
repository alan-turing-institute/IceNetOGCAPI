output "tags" {
  description = "Tags to apply to Azure resources"
  value = {
    "deployed_by" : "Terraform"
    "project" : "IceNet"
    "component" : "GeoAPI"
  }
}
output "project_name" {
  description = "Current project name used to construct Azure resource names"
  value       = "icenetgeoapi"
}
output "location" {
  description = "Which Azure location to build in"
  value       = "uksouth"
}
