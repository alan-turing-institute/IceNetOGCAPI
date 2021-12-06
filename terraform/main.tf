# PyGeoAPI app
module "pygeoapi" {
  source                      = "./pygeoapi"
  postgres_db_name            = var.postgres_db_name
  postgres_db_port            = var.postgres_db_port
  postgres_db_host            = var.postgres_db_host
  postgres_db_reader_username = var.postgres_db_reader_username
  postgres_db_reader_password = var.postgres_db_reader_password
}
