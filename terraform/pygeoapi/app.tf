# Create the resource group
resource "azurerm_resource_group" "app" {
  name     = "rg-${module.common.project_name}-pygeoapi"
  location = module.common.location
  tags     = local.tags
}

# Service plan that functions belong to
resource "azurerm_app_service_plan" "app" {
  name                = "plan-${module.common.project_name}-pygeoapi"
  resource_group_name = azurerm_resource_group.app.name
  location            = module.common.location
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
  name                = "app-${module.common.project_name}-pygeoapi"
  location            = module.common.location
  resource_group_name = azurerm_resource_group.app.name
  app_service_plan_id = azurerm_app_service_plan.app.id
  site_config {
    linux_fx_version = "Python|3.9"
    app_command_line = "python run.py"
  }
  app_settings = {
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "1",
    "POST_BUILD_COMMAND"             = "post_build.sh",
    "WEBSITES_PORT"                  = "8000",
  }
}
