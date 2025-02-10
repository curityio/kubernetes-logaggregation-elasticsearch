#!/bin/bash

#####################################################################################
# Complete the logging setup by creating Elasticsearch schemas and an ingest pipeline
# Then deploy filebeat so that it can start shipping Curity Identity Server logs
#####################################################################################

#
# Ensure that we are in the folder containing this script
#
cd "$(dirname "${BASH_SOURCE[0]}")"

#
# API connection details
#
ELASTIC_URL='http://api.elastic.local'
ELASTIC_USER='elastic'
ELASTIC_PASSWORD='Password1'
RESPONSE_FILE=response.txt

#
# Create the index for Curity system logs
#
cd resources
echo 'Creating Elasticsearch system index template ...'
HTTP_STATUS=$(curl -s -X PUT "$ELASTIC_URL/_index_template/curitysystem" \
-u "$ELASTIC_USER:$ELASTIC_PASSWORD" \
-H 'Content-Type: application/json' \
-d @indextemplate-curitysystem.json \
-o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '200' ]; then
  echo "*** Problem encountered creating the Curity system schema: $HTTP_STATUS"
  exit
fi

#
# Create the index for Curity request logs
#
echo 'Creating Elasticsearch request index template ...'
HTTP_STATUS=$(curl -s -X PUT "$ELASTIC_URL/_index_template/curityrequest" \
-u "$ELASTIC_USER:$ELASTIC_PASSWORD" \
-H 'Content-Type: application/json' \
-d @indextemplate-curityrequest.json \
-o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '200' ]; then
  echo "*** Problem encountered creating the Curity request schema: $HTTP_STATUS"
  exit
fi

#
# Script processors are tricky to manage via the REST API because the script must be flattened to a single line
# So get the ingest pipeline script processor's code into a single line and write '\n' literal characters
#
SCRIPTSOURCE=$(awk '{printf "\\\\n%s", $0}' script-processor.txt)

#
# Apply it to the ingest pipeline template file to get its full JSON
#
INGEST_PIPELINE_JSON=$(cat ingest-pipeline-template.json | sed s/SCRIPTSOURCE/"$SCRIPTSOURCE"/g)
echo "$INGEST_PIPELINE_JSON" > ingest-pipeline.json

#
# Delete then recreate the Curity ingest pipeline via REST, to control data transformation when logs are received
#
echo 'Creating Elasticsearch ingest pipeline ...'
curl -s -X DELETE "$ELASTIC_URL/_ingest/pipeline/curity-ingest-pipeline" -u "$ELASTIC_USER:$ELASTIC_PASSWORD" -o /dev/null
HTTP_STATUS=$(curl -s -X PUT "$ELASTIC_URL/_ingest/pipeline/curity-ingest-pipeline" \
-u "$ELASTIC_USER:$ELASTIC_PASSWORD" \
-H 'Content-Type: application/json' \
-d @ingest-pipeline.json \
-o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '200' ]; then
  echo "*** Problem encountered creating the Elasticsearch ingest pipeline: $HTTP_STATUS"
  exit
fi

#
# Finally apply the filebeat Daemonset which was downloaded from here and then edited to use the default namespace
# https://raw.githubusercontent.com/elastic/beats/7.15/deploy/kubernetes/filebeat-kubernetes.yaml
#
cd ../filebeat
kubectl -n elasticstack delete -f ./filebeat-kubernetes.yaml 2>/dev/null
kubectl -n elasticstack apply  -f ./filebeat-kubernetes.yaml
if [ $? -ne 0 ];
then
  echo 'Problem encountered applying filebeat configuration'
  exit 1
fi