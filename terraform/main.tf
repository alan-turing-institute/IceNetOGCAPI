# PyGeoAPI app
module "pygeoapi" {
  source                      = "./pygeoapi"
  postgres_db_name            = var.postgres_db_name
  postgres_db_host            = var.postgres_db_host
  postgres_db_reader_username = var.postgres_db_reader_username
  postgres_db_reader_password = var.postgres_db_reader_password
  pygeoapi_input_port         = "8000"
  default_tags                = local.tags
  project_name                = local.project_name
  location                    = var.location
  subnet                      = var.private_subnet
}
