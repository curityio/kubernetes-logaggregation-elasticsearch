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
cd ../resources
ELASTIC_URL='https://api.curitylogs.local'
ELASTIC_USER='elastic'
ELASTIC_PASSWORD='Password1'
RESPONSE_FILE=response.txt
echo 'Waiting for the Elasticsearch service ...'
while [ "$(curl -k -s -o /dev/null -w ''%{http_code}'' -u "$ELASTIC_USER:$ELASTIC_PASSWORD" "$ELASTIC_URL")" != "200" ]; do
  sleep 2s
done

#
# Create the Curity logs schemas to receive fields in a queryable manner
#
echo 'Creating Elasticsearch schema ...'
HTTP_STATUS=$(curl -s -X PUT "$ELASTIC_URL/curitysystem" \
-u "$ELASTIC_USER:$ELASTIC_PASSWORD" \
-H 'Content-Type: application/json' \
-d @./create-schema.json \
-o $RESPONSE_FILE -w '%{http_code}')
if [ $HTTP_STATUS != '200' ]; then
  echo "*** Problem encountered creating the Elasticsearch schema: $HTTP_STATUS"
  exit
fi

#
# Create the Curity ingestion pipelines to control which records are received
#
echo 'Creating Elasticsearch ingestion pipeline ...'
HTTP_STATUS=$(curl -s -X PUT "$ELASTIC_URL/_ingest/pipeline/curitysystem-ingest-pipeline" \
-u "$ELASTIC_USER:$ELASTIC_PASSWORD" \
-H 'Content-Type: application/json' \
-d @./create-ingestion-pipeline.json \
-o $RESPONSE_FILE -w '%{http_code}')
if [ $HTTP_STATUS != '200' ]; then
  echo "*** Problem encountered creating the Elastic Search API logs ingestion pipeline: $HTTP_STATUS"
  exit
fi

#
# Apply the filebeat Daemonset which was downloaded from here and then edited to use the default namespace
# https://raw.githubusercontent.com/elastic/beats/7.15/deploy/kubernetes/filebeat-kubernetes.yaml
#
cd ../filebeat
kubectl delete -f ./filebeat-kubernetes.yaml 2>/dev/null
kubectl apply -f ./filebeat-kubernetes.yaml
if [ $? -ne 0 ];
then
  echo 'Problem encountered applying filebeat configuration'
  exit 1
fi