#!/bin/bash

###########################################
# Deploy Elasticsearch, Kibana and Filebeat
###########################################

cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Create a Docker container that runs a job to create the ingestion pipeline
#
cd ingestion
docker build -t elastic-initdata-job:1.0.0 .
if [ $? -ne 0 ]; then
  exit 1
fi

kind load docker-image elastic-initdata-job:1.0.0 --name demo
if [ $? -ne 0 ]; then
  exit 1
fi
cd ..

#
# Deploy Elasticsearch and Kibana and run the init job
#
kubectl delete namespace elasticstack 2>/dev/null
kubectl create namespace elasticstack
kubectl -n elasticstack apply -f elasticsearch.yaml
kubectl -n elasticstack apply -f kibana.yaml

#
# Wait for the job to complete so that index templates get created before indexes get created
# This ensures that JSON logs reecived from Filebeat get ingested with the correct data types
#
echo 'Waiting for the initialization job to configure ingestion ...'
kubectl -n elasticstack wait --for=condition=complete job/elastic-initdata-job --timeout=300s

#
# Then deploy filebeat
#
kubectl -n elasticstack apply -f filebeat.yaml
