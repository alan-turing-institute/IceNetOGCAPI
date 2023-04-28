# Create the resource group
resource "azurerm_resource_group" "app" {
  name     = "rg-${var.project_name}-pygeoapi"
  location = var.location
  tags     = local.tags
}

# Service plan that functions belong to
resource "azurerm_app_service_plan" "app" {
  name                = "plan-${var.project_name}-pygeoapi"
  resource_group_name = azurerm_resource_group.app.name
  location            = var.location
  kind                = "Linux"
  reserved            = true
  sku {
    tier = local.app_sku_category
    size = local.app_sku
  }
  lifecycle {
    ignore_changes = [kind]
  }
  tags = local.tags
}

resource "azurerm_app_service" "app" {
  name                = "app-${var.project_name}-pygeoapi"
  location            = var.location
  resource_group_name = azurerm_resource_group.app.name
  app_service_plan_id = azurerm_app_service_plan.app.id
  site_config {
    always_on        = true
    app_command_line = "python run.py"
    linux_fx_version = "Python|3.9"
    virtual_network_subnet_id  = var.subnet
  }
  app_settings = {
    "POST_BUILD_COMMAND"             = "post_build.sh",
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "1",
    "WEBSITES_PORT"                  = "${var.pygeoapi_input_port}",
  }
}
