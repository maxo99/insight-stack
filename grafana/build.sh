#!/bin/bash

# Read version from parent directory
VERSION=$(grep -oP '(?<=version=).*' ../version)


GRAFANA_DIR=../docker_data/grafana/
mkdir -p ${GRAFANA_DIR}

## Copy Provisioning DataSource
cp -r -u datasources ${GRAFANA_DIR}

## Copy Provisioning Dashboards
cp -r -u dashboards ${GRAFANA_DIR}

docker build --no-cache -t maxo99/grafana:${VERSION} -t maxo99/grafana:latest  .
# docker push maxo99/grafana:latest

