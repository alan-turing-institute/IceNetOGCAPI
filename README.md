# IceNetGeoAPI

OGC-compatible API for exposing IceNet predictions.
This is part of the [IceNet project](https://icenet.ai).

## Azure

This requires the [icenet ETL infrastructure](https://github.com/icenet-ai/icenet-etl) to be insantiated.

The icenetgeoapi folder contains the installable webapp that can be deployed to this platform.

More details TBC

## Run the example notebooks

### Python

Install `Python` requirements with the following:

- `pip install -r examples/requirements.txt`

### Jupyter

Go into the `examples` directory and run `jupyter notebook`.

- `api-usage-latest-forecasts.ipynb` demonstrates how to retrieve the most up-to-date forecasts from the API.
- `api-usage-historic-forecasts.ipynb` demonstrates how to retrieve forecasts created by older versions of the IceNet model.
