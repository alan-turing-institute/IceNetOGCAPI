# These variables must be passed at the command line
variable "postgres_db_name" {
  description = "Name of the PostgreSQL database containing data."
  type        = string
}
variable "postgres_db_host" {
  description = "Hostname used by the PostgreSQL database containing data."
  type        = string
}
variable "postgres_db_reader_username" {
  description = "Username for an account with read access to the PostgreSQL database containing data."
  type        = string
  sensitive   = true
}
variable "postgres_db_reader_password" {
  description = "Password for an account with read access to the PostgreSQL database containing data."
  type        = string
  sensitive   = true
}
variable "subscription_id" {
  description = "Which Azure subscription to build in"
  type        = string
}
variable "tenant_id" {
  description = "Which Azure tenant to build in"
  type        = string
}
variable "environment" {
  description = "Environment we're building"
  default     = "dev"
}
variable "project_prefix" {
  description = "Current project prefix used to construct Azure resource names"
  default     = "icenetgeoapi"
}
variable "location" {
  description = "Which Azure location to build in"
  default     = "uksouth"
}
# Local variables
locals {
  database_names = ["icenet"]
  project_name   = "${var.project_prefix}${var.environment}"
  tags = {
    "deployed_by" : "Terraform"
    "project" : "IceNet"
    "component" : "GeoAPI"
  }
}

