# Load common module
module "common" {
  source = "../common"
}

variable "postgres_db_name" {
  description = "Name of the PostgreSQL database containing data"
  type        = string
}
variable "postgres_db_port" {
  description = "Port used by the PostgreSQL database containing data."
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

# Local variables
locals {
  tags = merge(
    {
      "module" = "pygeoapi"
    },
    module.common.tags,
  )
  # Basic B1: 100 total ACU, 1.75 GB memory £9.49/month
  # Premium P1V2: 210 total ACU, 3.5 GB memory £60.59/month
  # Premium P1V3: 195 total ACU, 8 GB memory £92.49/month
  # Premium P2V3: 195 total ACU, 16 GB memory £184.98/month
  app_sku_category = "Standard"
  app_sku          = "S1"
}
