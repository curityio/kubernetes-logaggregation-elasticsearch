#!/bin/bash

############################################################################
# Deploy Elastic Stack components to an existing Kubernetes minikube cluster
# This simple setup destroys all existing data whenever this script is run
############################################################################

#
# Deploy Elastic Search in a basic single node setup and expose it over port 443
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
# Deploy Kibana and expose it over port 443
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
ELASTIC_URL='https://api.curitylogs.local'
ELASTIC_USER='elastic'
ELASTIC_PASSWORD='Password1'
echo 'Waiting for the Elasticsearch service ...'
while [ "$(curl -k -s -o /dev/null -w ''%{http_code}'' -u "$ELASTIC_USER:$ELASTIC_PASSWORD" "$ELASTIC_URL")" != "200" ]; do
  sleep 2s
done

#
# Create schemas
#
cd ../resources
echo 'Initialising log setup in Elastic Search ...'
