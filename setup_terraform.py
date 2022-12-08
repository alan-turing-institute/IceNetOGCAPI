#! /usr/bin/env python3
import argparse
import coloredlogs
import hcl
import logging
import os
from azure.identity import InteractiveBrowserCredential
from azure.mgmt.resource import ResourceManagementClient, SubscriptionClient
from azure.core.exceptions import ClientAuthenticationError, HttpResponseError
from azure.mgmt.storage import StorageManagementClient


def main():
    """Setup initial Azure infrastructure used by Terraform"""
    # Disable unnecessarily verbose Azure logging
    logging.getLogger("azure.identity._internal").setLevel(logging.ERROR)
    logging.getLogger("azure.identity._credentials").setLevel(logging.ERROR)
    logging.getLogger("azure.core.pipeline.policies").setLevel(logging.ERROR)

    # Parse command line arguments
    parser = argparse.ArgumentParser(
        description="Initialise the Azure infrastructure needed by Terraform"
    )
    parser.add_argument(
        "-s",
        "--azure-subscription-name",
        type=str,
        default="IceNet",
        help="Name of the Azure subscription being used.",
    )
    parser.add_argument(
        "--postgres-db-name",
        type=str,
        default="icenet",
        help="Name of the PostgreSQL database containing data.",
    )
    parser.add_argument(
        "--postgres-db-host",
        type=str,
        default="psql-icenetetl-database",
        help="Hostname used by the PostgreSQL database containing data.",
    )
    parser.add_argument(
        "-u",
        "--postgres-db-reader-username",
        type=str,
        default="icenetreader",
        help="Username for an account with read access to the PostgreSQL database containing data. Look in kv-icenetetl-secrets if unsure.",
    )
    parser.add_argument(
        "-p",
        "--postgres-db-reader-password",
        type=str,
        help="Password for an account with read access to the PostgreSQL database containing data. Look in kv-icenetetl-secrets if unsure.",
        required=True,
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Verbosity level: each '-v' will increase logging level by one step (default is WARNING).",
    )

    # Configure logging, increasing verbosity by one level for each 'v'
    args = parser.parse_args()
    verbosity = max(logging.WARNING - (10 * args.verbose), 0)
    coloredlogs.install(fmt="%(asctime)s %(levelname)8s: %(message)s", level=verbosity)

    # Set Terraform variables
    tags = {
        "deployed_by": "Python",
        "project": "IceNet",
        "component": "GeoAPI",
    }
    # Load variables from backend.tf
    with open(os.path.join("terraform", "backend.tf"), "r") as f_in:
        config = hcl.load(f_in)
    az_config = config["terraform"]["backend"]["azurerm"]
    resource_group_name = az_config["resource_group_name"]
    storage_account_name = az_config["storage_account_name"]
    storage_container_name = az_config["container_name"]

    # Get a common Azure information
    credential = InteractiveBrowserCredential()
    subscription_id, tenant_id = get_azure_ids(credential, args.azure_subscription_name)

    # Configure the Terraform backend
    configure_terraform_backend(
        credential,
        subscription_id,
        resource_group_name,
        storage_account_name,
        storage_container_name,
        tags=tags,
    )
    storage_key = load_terraform_storage_key(
        credential, subscription_id, resource_group_name, storage_account_name
    )

    # Write Terraform configs to file
    write_terraform_configs(
        subscription_id,
        tenant_id,
        storage_key,
        postgres_db_name=args.postgres_db_name,
        postgres_db_host=args.postgres_db_host,
        postgres_db_reader_username=args.postgres_db_reader_username,
        postgres_db_reader_password=args.postgres_db_reader_password,
    )


def get_azure_ids(credential, subscription_name):
    """Get subscription and tenant IDs"""
    # Connect to Azure clients
    subscription_client = SubscriptionClient(credential=credential)

    # Check that the Azure credentials are valid
    try:
        for subscription in subscription_client.subscriptions.list():
            logging.debug(
                f"Found subscription {subscription.display_name} ({subscription.id})"
            )
            if subscription.display_name == subscription_name:
                subscription_id = subscription.subscription_id
                tenant_id = subscription.tenant_id
        logging.info(
            f"Successfully authenticated using: {credential.__class__.__name__}"
        )
    except ClientAuthenticationError:
        logging.error(
            "Failed to authenticate with Azure! Please ensure that you can use one of the methods below:"
        )
        raise
    return (subscription_id, tenant_id)


def write_terraform_configs(subscription_id, tenant_id, storage_key, **kwargs):
    """Write Terraform config files"""
    # Backend secrets
    backend_secrets_path = os.path.join("terraform", "backend.secrets")
    logging.info(f"Writing Terraform backend secrets to {backend_secrets_path}")
    backend_secrets = {
        "access_key": storage_key,
    }
    with open(backend_secrets_path, "w") as f_out:
        for key, value in backend_secrets.items():
            f_out.write(f'{key} = "{value}"\n')

    # Azure secrets
    azure_secrets_path = os.path.join("terraform", "azure.secrets")
    logging.info(f"Writing Azure tenancy details to {azure_secrets_path}")
    azure_vars = {
        "subscription_id": subscription_id,
        "tenant_id": tenant_id,
    }
    azure_vars.update(kwargs)
    with open(azure_secrets_path, "w") as f_out:
        for key, value in azure_vars.items():
            # Strings must be quoted but lists must not be
            value_ = f'"{value}"' if isinstance(value, str) else value
            # Write to output file after replacing any single quotes
            f_out.write(f"{key} = {value_}\n".replace("'", '"'))


def configure_terraform_backend(
    credential,
    subscription_id,
    resource_group_name,
    storage_account_name,
    storage_container_name,
    tags={},
    location="uksouth",
):
    """Ensure that Terraform backend resources are configured"""
    # Connect to Azure clients
    resource_client = ResourceManagementClient(credential, subscription_id)
    storage_client = StorageManagementClient(credential, subscription_id)

    # Ensure that resource group exists
    logging.info(f"Ensuring that resource group {resource_group_name} exists...")
    resource_client.resource_groups.create_or_update(
        resource_group_name, {"location": location, "tags": tags}
    )
    for resource_group in filter(
        lambda group: group.name == resource_group_name,
        resource_client.resource_groups.list(),
    ):
        logging.info(
            f"Found resource group {resource_group.name} in {resource_group.location}"
        )

    # Ensure that storage account exists
    logging.info(f"Ensuring that storage account {storage_account_name} exists...")
    try:
        poller = storage_client.storage_accounts.begin_create(
            resource_group_name,
            storage_account_name,
            {
                "location": location,
                "kind": "StorageV2",
                "sku": {"name": "Standard_LRS"},
                "tags": tags,
            },
        )
        storage_account = poller.result()
        logging.info(
            f"Found storage account {storage_account.name} in {storage_account.location}"
        )
    except HttpResponseError:
        logging.error(f"Failed to create storage account {storage_account_name}!")
        raise

    # Ensure that storage container exists
    logging.info(f"Ensuring that storage container {storage_container_name} exists...")
    try:
        container = storage_client.blob_containers.create(
            resource_group_name,
            storage_account_name,
            storage_container_name,
            {"public_access": "none"},
        )
        logging.info(f"Found storage container {container.name}")
    except HttpResponseError:
        logging.error("Failed to create storage account {storage_account_name}!")
        raise


def load_terraform_storage_key(
    credential,
    subscription_id,
    resource_group_name,
    storage_account_name,
):
    """Load Terraform storage key"""
    # Connect to Azure clients
    storage_client = StorageManagementClient(credential, subscription_id)

    # Return the first storage account key
    storage_keys = storage_client.storage_accounts.list_keys(
        resource_group_name, storage_account_name
    )
    return storage_keys.keys[0].value


if __name__ == "__main__":
    main()
