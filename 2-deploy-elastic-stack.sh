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
# Create the Curity system log schema
#
echo 'Creating Elasticsearch system schema ...'
HTTP_STATUS=$(curl -s -X PUT "$ELASTIC_URL/curitysystem" \
-u "$ELASTIC_USER:$ELASTIC_PASSWORD" \
-H 'Content-Type: application/json' \
-o $RESPONSE_FILE -w '%{http_code}')
if [ $HTTP_STATUS != '200' ]; then
  echo "*** Problem encountered creating the Curity system schema: $HTTP_STATUS"
  exit
fi

#
# Create the Curity request log schema
#
echo 'Creating Elasticsearch request schema ...'
HTTP_STATUS=$(curl -s -X PUT "$ELASTIC_URL/curityrequest" \
-u "$ELASTIC_USER:$ELASTIC_PASSWORD" \
-H 'Content-Type: application/json' \
-o $RESPONSE_FILE -w '%{http_code}')
if [ $HTTP_STATUS != '200' ]; then
  echo "*** Problem encountered creating the Curity request schema: $HTTP_STATUS"
  exit
fi

#
# Create the Curity ingestion pipeline to control how data is received
# The source processor's code was typed into Kibana, then the 'Copy as cURL' option was used to get the below data:
# https://discuss.elastic.co/t/pipeline-processor-script-error/149508
#
echo 'Creating Elasticsearch ingestion pipeline ...'
HTTP_STATUS=$(curl -s -X PUT "$ELASTIC_URL/_ingest/pipeline/curity-ingest-pipeline" \
-u "$ELASTIC_USER:$ELASTIC_PASSWORD" \
-H 'Content-Type: application/json' \
-d'
{
  "description": "Curity System Logs Ingestion Pipeline",
  "processors": [
    {
      "script": {
        "description": "Set the index based on the logger name received",
        "source": "\n\n          String loggerName = ctx['\''loggerName'\''];\n          if (loggerName != null && loggerName.contains('\''RequestReceiver'\'')) {\n            ctx['\''_index'\''] = '\''curityrequest'\'';\n          } else {\n            ctx['\''_index'\''] = '\''curitysystem'\'';\n          }\n        "
      }
    }
  ]
}' \
-o $RESPONSE_FILE -w '%{http_code}')

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