#!/bin/bash

#################################################################################
# Deploy Elastic Stack base components to an existing Kubernetes minikube cluster
# This simple setup destroys all existing data whenever this script is run
#################################################################################

ELASTIC_URL='http://api.elastic.local'
ELASTIC_USER='elastic'
ELASTIC_PASSWORD='Password1'
RESPONSE_FILE=response.txt

#
# Deploy Elastic Search in a basic single node setup and expose it over port 80
#
cd elastic
kubectl delete -f service.yaml 2>/dev/null
kubectl apply -f service.yaml
if [ $? -ne 0 ];
then
  echo 'Problem encountered applying ElasticSearch service'
  exit 1
fi
kubectl delete -f ingress.yaml 2>/dev/null
kubectl apply -f ingress.yaml

#
# Deploy Kibana and expose it over port 80
#
cd ../kibana
kubectl delete -f service.yaml 2>/dev/null
kubectl apply -f service.yaml
if [ $? -ne 0 ];
then
  echo 'Problem encountered applying ElasticSearch service'
  exit 1
fi
kubectl delete -f ingress.yaml 2>/dev/null
kubectl apply -f ingress.yaml

#
# Wait for the Elasticsearch service
#
echo 'Waiting for the Elasticsearch service ...'
while [ "$(curl -k -s -o /dev/null -w ''%{http_code}'' -u "$ELASTIC_USER:$ELASTIC_PASSWORD" "$ELASTIC_URL")" != "200" ]; do
  sleep 2
done

#
# Wait for the Kibana service
#
KIBANA_URL='http://elastic.local'
echo 'Waiting for Kibana to come online ...'
while [ "$(curl -k -s -o /dev/null -w ''%{http_code}'' -u "$ELASTIC_USER:$ELASTIC_PASSWORD" "$ELASTIC_URL")" != "200" ]; do
  sleep 2
done
