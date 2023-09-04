#SHELL := bash
#.ONESHELL:
#.SHELLFLAGS := -eu -o pipefail

ICENET_ENV?=dev
ICENET_AZ_APPLICATION?=app-icenet$(ICENET_ENV)-pygeoapi
ICENET_RG?=rg-icenet$(ICENET_ENV)-webapps

.PHONY: clean

clean:
	rm icenetgeoapi.zip

deploy-azure: icenetgeoapi/pygeoapi.secrets
	./make_config.sh
	./make_package.sh
	az webapp deployment source config-zip --name ${ICENET_AZ_APPLICATION} --src icenetgeoapi.zip -g ${ICENET_RG}
