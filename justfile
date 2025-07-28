# justfile

set dotenv-load

# Variables
DOCKERHUB_USER := "maxo5499"
DOCKER_DATA := "./.docker_data"
## Grafana
GRAFANA_CONTAINER := "insightstack-grafana"
GRAFANA_SRC := "./grafana"
GRAFANA_DATA := DOCKER_DATA + "/grafana"
## Collector-WeatherFlow
WF_CONTAINER := "insightstack-collector-weatherflow"
WEATHERFLOW_SRC := "./weatherflow-collector"
WEATHERFLOW_DATA := DOCKER_DATA + "/collector-weatherflow"
## Collector-Garmin
COLLECTOR_GARMIN := "insightstack-collector-garmin"
GARMIN_SRC := "./garmin-grafana"
GARMIN_DATA := DOCKER_DATA + "/collector-garmin"


# Default recipe to show available commands
default:
	@just --list


# evaluate and print all just variables
evaluate:
	@just --evaluate

test-version:
	@just get-version

get-version:
   echo `grep -oP '(?<=version=).*' ./version`

# build-grafana: get-version
#	 #!/usr/bin/env bash
#	 set -euxo pipefail
#	 VERSION=`just get-version`
#	 echo "Building {{GRAFANA_CONTAINER}}:${VERSION}"
#	 cd {{GRAFANA_SRC}} && docker build -t {{GRAFANA_CONTAINER}}:${VERSION} -t {{GRAFANA_CONTAINER}}:latest .
#	 echo "Grafana container built successfully."

build-wf: get-version
	#!/usr/bin/env bash
	set -euxo pipefail
	VERSION=`just get-version`
	echo "Building {{WF_CONTAINER}}:${VERSION}"
	cd {{WEATHERFLOW_SRC}} && docker build -t {{DOCKERHUB_USER}}/{{WF_CONTAINER}}:${VERSION} -t {{DOCKERHUB_USER}}/{{WF_CONTAINER}}:latest .
	echo "Built {{WF_CONTAINER}}:${VERSION}"


build-collector-garmin: get-version
	#!/usr/bin/env bash
	set -euxo pipefail
	VERSION=`just get-version`
	echo "Building {{COLLECTOR_GARMIN}}:${VERSION}"
	cd {{GARMIN_SRC}} && docker build -t {{DOCKERHUB_USER}}/{{COLLECTOR_GARMIN}}:${VERSION} -t {{DOCKERHUB_USER}}/{{COLLECTOR_GARMIN}}:latest .
	echo "Built {{COLLECTOR_GARMIN}}:${VERSION}"

build-collectors:
	just build-wf
	just build-collector-garmin

logs-g:
	docker compose logs -f {{GRAFANA_CONTAINER}}

logs-wf:
	docker compose logs -f {{WF_CONTAINER}}


# Copy provisioning files to running Grafana container
update-provisioning:
	@echo "Updating provisioning files in running container..."
	cp {{GRAFANA_SRC}}/provisioning/dashboards/*.yml {{DOCKER_DATA}}/grafana/provisioning/dashboards/
	cp {{GRAFANA_SRC}}/provisioning/datasources/*.yml {{DOCKER_DATA}}/grafana/provisioning/datasources/
	@echo "Provisioning files updated successfully"
# 	cp {{GRAFANA_SRC}}
#	 docker cp {{GRAFANA_SRC}}/provisioning/dashboards/*.yml {{GRAFANA_CONTAINER}}:/etc/grafana/provisioning/dashboards/
#	 docker cp {{GRAFANA_SRC}}/provisioning/datasources/*.yml {{GRAFANA_CONTAINER}}:/etc/grafana/provisioning/datasources/


create-dockerdata-dirs:
	@echo "Creating Docker data directories..."
	mkdir -p {{DOCKER_DATA}}/grafana/provisioning/dashboards
	mkdir -p {{DOCKER_DATA}}/grafana/provisioning/datasources
	mkdir -p {{DOCKER_DATA}}/grafana/dashboards
	mkdir -p {{DOCKER_DATA}}/garminconnect/tokens
	chown -R 1000:1000 {{DOCKER_DATA}}/garminconnect
	mkdir -p {{DOCKER_DATA}}/collector-weatherflow
	@echo "Docker data directories created successfully"

update-dashboards:
	@echo "Updating dashboards in running container..."
	docker cp {{GRAFANA_SRC}}/dashboards/mine {{GRAFANA_CONTAINER}}:/var/lib/grafana/dashboards/mine
	docker cp {{GRAFANA_SRC}}/dashboards/garmin {{GRAFANA_CONTAINER}}:/var/lib/grafana/dashboards/garmin
	docker cp {{GRAFANA_SRC}}/dashboards/weatherflow-collector {{GRAFANA_CONTAINER}}:/var/lib/grafana/dashboards/weatherflow-collector
	@echo "Dashboards updated successfully"

save-dashboards:
	@echo "Saving dashboards from running container..."
	docker cp {{GRAFANA_CONTAINER}}:/var/lib/grafana/dashboards/mine {{GRAFANA_SRC}}/dashboards
	docker cp {{GRAFANA_CONTAINER}}:/var/lib/grafana/dashboards/garmin {{GRAFANA_SRC}}/dashboards
	docker cp {{GRAFANA_CONTAINER}}:/var/lib/grafana/dashboards/weatherflow-collector {{GRAFANA_SRC}}/dashboards

clean-docker-data:
	@echo "Cleaning up Docker data directories..."
	docker compose down
	docker volume rm insight-stack_grafana_data || true
	rm -rf {{DOCKER_DATA}}

recreate-all:
	just clean-docker-data
	just create-dockerdata-dirs
	just update-provisioning
	docker compose up -d
	just update-dashboards
	just logs-g