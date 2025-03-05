#!/bin/bash

###########################################
# Deploy Elasticsearch, Kibana and Filebeat
###########################################

cd "$(dirname "${BASH_SOURCE[0]}")"

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

kubectl delete namespace elasticstack 2>/dev/null
kubectl create namespace elasticstack
kubectl -n elasticstack apply -f elasticsearch.yaml
kubectl -n elasticstack apply -f kibana.yaml
kubectl -n elasticstack apply -f filebeat.yaml
