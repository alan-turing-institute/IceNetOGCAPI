# Generate config files
resource "null_resource" "write_config" {
  # Redeployment triggers
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<EOF
    cd ../icenetgeoapi
    echo 'app_url: ${azurerm_app_service.app.default_site_hostname}' > pygeoapi.secrets
    echo 'port: ${var.postgres_db_port}' >> pygeoapi.secrets
    echo 'postgres_dbname: ${var.postgres_db_name}' >> pygeoapi.secrets
    echo 'postgres_host: ${var.postgres_db_host}' >> pygeoapi.secrets
    echo 'postgres_reader_password: ${var.postgres_db_reader_password}' >> pygeoapi.secrets
    echo 'postgres_reader_username: ${var.postgres_db_reader_username}' >> pygeoapi.secrets
    python generate_config.py
    cd -
    EOF
  }
}

# Create a local archive
data "archive_file" "deploy" {
  # Define build order
  depends_on  = [null_resource.write_config]
  type        = "zip"
  source_dir  = "../icenetgeoapi"
  output_path = "icenetgeoapi.zip"
}

# Deploy from local zip file
resource "null_resource" "deploy_zip" {
  # Define build order
  depends_on = [null_resource.write_config, data.archive_file.deploy]

  # Redeployment triggers
  triggers = {
    zip_file    = "${data.archive_file.deploy.id}"
    config_file = "${null_resource.write_config.id}"
  }

  provisioner "local-exec" {
    command = <<EOF
    echo "Waiting for other deployments to finish..."
    #sleep 300
    sleep 3
    echo "Deploying app from $(pwd)"
    az webapp deployment source config-zip --resource-group ${azurerm_resource_group.app.name} --name ${azurerm_app_service.app.name} --src ${data.archive_file.deploy.output_path}
    echo "Removing ${data.archive_file.deploy.output_path}"
    rm ${data.archive_file.deploy.output_path}
    EOF
  }
}