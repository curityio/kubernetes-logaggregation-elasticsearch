#!/bin/bash

######################################################################################
# A Kubernetes job to initialize Elasticsearch data and prepare the ingestion pipeline
######################################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"

ELASTICSEARCH_URL='http://elastic-svc:9200'
ELASTICSEARCH_USER='elastic'
ELASTICSEARCH_PASSWORD='Password1'
KIBANA_SYSTEM_USER='kibana_system'
KIBANA_SYSTEM_PASSWORD='Password1'
RESPONSE_FILE=response.txt

#
# Wait until Elasticsearch is ready
#
echo 'Waiting for Elasticsearch endpoints to become available ...'
while [ "$(curl -k -s -o /dev/null -w ''%{http_code}'' "$ELASTICSEARCH_URL" -u "$ELASTICSEARCH_USER:$ELASTICSEARCH_PASSWORD")" != '200' ]; do
  sleep 2
done

#
# Register the kibana system user's password in Elasticsearch to prevent a 'Kibana server is not ready yet' error
# https://www.elastic.co/guide/en/elasticsearch/reference/7.17/breaking-changes-7.8.html#builtin-users-changes
#
echo 'Setting the Kibana system user password ...'
HTTP_STATUS=$(curl -k -s -X POST "$ELASTICSEARCH_URL/_security/user/$KIBANA_SYSTEM_USER/_password" \
  -u "$ELASTICSEARCH_USER:$ELASTICSEARCH_PASSWORD" \
  -H "content-type: application/json" \
  -d "{\"password\":\"$KIBANA_SYSTEM_PASSWORD\"}" \
  -o $RESPONSE_FILE \
  -w '%{http_code}')
if [ "$HTTP_STATUS" != '200' ]; then
  echo "*** Problem encountered setting the Kibana system password: $HTTP_STATUS"
  cat "$RESPONSE_FILE"
fi

#
# Create the index template for Curity system logs
#
echo 'Creating the system logs index template ...'
HTTP_STATUS=$(curl -k -s -X PUT "$ELASTICSEARCH_URL/_index_template/curity-system" \
  -u "$ELASTICSEARCH_USER:$ELASTICSEARCH_PASSWORD" \
  -H "content-type: application/json" \
  -d @indextemplate-curity-system.json \
  -o $RESPONSE_FILE \
  -w '%{http_code}')
if [ "$HTTP_STATUS" != '200' ]; then
  echo "*** Problem encountered creating the system logs index template: $HTTP_STATUS"
  cat "$RESPONSE_FILE"
fi

#
# Create the index template for Curity request logs
#
echo 'Creating the request logs index template ...'
HTTP_STATUS=$(curl -k -s -X PUT "$ELASTICSEARCH_URL/_index_template/curity-request" \
  -u "$ELASTICSEARCH_USER:$ELASTICSEARCH_PASSWORD" \
  -H "content-type: application/json" \
  -d @indextemplate-curity-request.json \
  -o $RESPONSE_FILE \
  -w '%{http_code}')
if [ "$HTTP_STATUS" != '200' ]; then
  echo "*** Problem encountered creating the request logs index template: $HTTP_STATUS"
  cat "$RESPONSE_FILE"
fi

#
# Create the index template for Curity audit logs
#
echo 'Creating the audit logs index template ...'
HTTP_STATUS=$(curl -k -s -X PUT "$ELASTICSEARCH_URL/_index_template/curity-audit" \
  -u "$ELASTICSEARCH_USER:$ELASTICSEARCH_PASSWORD" \
  -H "content-type: application/json" \
  -d @indextemplate-curity-audit.json \
  -o $RESPONSE_FILE \
  -w '%{http_code}')
if [ "$HTTP_STATUS" != '200' ]; then
  echo "*** Problem encountered creating the audit logs index template: $HTTP_STATUS"
  cat "$RESPONSE_FILE"
fi

#
# Create the Curity ingest pipeline to control receiving data and fail the job on error
#
echo 'Creating the Elasticsearch ingest pipeline ...'
HTTP_STATUS=$(curl -s -X PUT "$ELASTICSEARCH_URL/_ingest/pipeline/curity-ingest-pipeline" \
  -u "$ELASTICSEARCH_USER:$ELASTICSEARCH_PASSWORD" \
  -H 'Content-Type: application/json' \
  -d @ingest-pipeline.json \
  -o $RESPONSE_FILE -w '%{http_code}')
if [ "$HTTP_STATUS" != '200' ]; then
  echo "*** Problem encountered creating the Elasticsearch ingest pipeline: $HTTP_STATUS"
  cat "$RESPONSE_FILE"
  exit 1
fi
