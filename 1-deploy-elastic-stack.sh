#!/bin/bash

#################################################################################
# Deploy Elastic Stack base components to an existing Kubernetes minikube cluster
# This simple setup destroys all existing data whenever this script is run
#################################################################################

#
# Ensure that we are in the folder containing this script
#
cd "$(dirname "${BASH_SOURCE[0]}")"


curl -u "elastic:Password1" "http://api.elastic.local/_security/user/kibana_system/_password" \
-u "elastic:Password1" \
-H "content-type: application/json" \
-d "{\"password\":\"Password1\"}" \
-o /dev/null \
-w '%{http_code}'

#
# API connection details
#
ELASTIC_URL='http://api.elastic.local'
ELASTIC_USER='elastic'
ELASTIC_PASSWORD='Password1'
KIBANA_SYSTEM_USER='kibana_system'
KIBANA_SYSTEM_PASSWORD='Password1'
RESPONSE_FILE=response.txt

#
# First create the namespace
#
kubectl create namespace elasticstack 2>/dev/null

#
# Deploy services
#
kubectl -n elasticstack apply -f elastic/service.yaml
kubectl -n elasticstack apply -f kibana/service.yaml

#
# Deploy ingress resources
#
kubectl -n apigateway   apply -f gateway/gateway.yaml
kubectl -n elasticstack apply -f elastic/ingress.yaml
kubectl -n elasticstack apply -f kibana/ingress.yaml

#
# Wait for the Elasticsearch service
#
echo 'Waiting for the Elasticsearch service ...'
while [ "$(curl -k -s -o /dev/null -w ''%{http_code}'' -u "$ELASTIC_USER:$ELASTIC_PASSWORD" "$ELASTIC_URL")" != "200" ]; do
  sleep 2
done

#
# Set a password for the kibana_system user
#
echo 'Setting the Kibana system user password ...'
HTTP_STATUS=$(curl -k -s -X POST "$ELASTIC_URL/_security/user/$KIBANA_SYSTEM_USER/_password" \
-u "$ELASTIC_USER:$ELASTIC_PASSWORD" \
-H "content-type: application/json" \
-d "{\"password\":\"$KIBANA_SYSTEM_PASSWORD\"}" \
-o /dev/null \
-w '%{http_code}')
if [ "$HTTP_STATUS" != '200' ]; then
  echo "*** Problem encountered setting the Kibana system password: $HTTP_STATUS"
  exit 1
fi

#
# Wait for the Kibana service
#
KIBANA_URL='http://elastic.local'
echo 'Waiting for Kibana to come online ...'
while [ "$(curl -k -s -o /dev/null -w ''%{http_code}'' -u "$ELASTIC_USER:$ELASTIC_PASSWORD" "$ELASTIC_URL")" != "200" ]; do
  sleep 2
done
