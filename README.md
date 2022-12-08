# IceNetGeoAPI

OGC-compatible API for exposing IceNet predictions.
This is part of the [IceNet project](https://github.com/alan-turing-institute/IceNet-Project).

## Prerequisites

You will need to install the following in order to use this package:

- A [`Microsoft Azure`](https://portal.azure.com) account with at least `Contributor` permissions on the `IceNet` subscription
- [`Hashicorp Terraform`](https://www.terraform.io/)
- `Python 3.9` (this is the latest version supported by `Azure Functions`)

## Setup the Azure infrastructure

### Python

Install `Python` requirements with the following:

- `pip install --upgrade pip poetry`
- `poetry install` or

### Setup the Terraform backend

- Run the `Terraform` setup script `./setup_terraform.py -v`
- Enter the `terraform` directory with `cd terraform`
- Initialise `Terraform` by running `terraform init -backend-config=backend.secrets`
- Check the actions that `Terraform` will carry out by running `terraform plan -var-file=azure.secrets`
- Deploy using `Terraform` by running `terraform apply -var-file=azure.secrets`

## Run the example notebooks

### Python

Install `Python` requirements with the following:

- `pip install --upgrade pip poetry`
- `poetry install --extras notebook`

### Jupyter

Go into the `examples` directory and run `jupyter notebook`.

- `api-usage-latest-forecasts.ipynb` demonstrates how to retrieve the most up-to-date forecasts from the API.
- `api-usage-historic-forecasts.ipynb` demonstrates how to retrieve forecasts created by older versions of the IceNet model.
