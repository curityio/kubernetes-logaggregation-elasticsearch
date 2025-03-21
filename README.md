# Curity Identity Server Log Aggregation to Elastic Search

Aggregates the following logs to Elasticsearch, where logs include OpenTelemetry trace and span IDs.

- System logs
- Request logs
- Audit logs

## Prerequisites

Start with base deployments such as the following examples from the Kubernetes Training repository.

- The [Curity Identity Server](https://github.com/curityio/kubernetes-training?tab=readme-ov-file#3---curity-identity-server-example) example deployment.
- The [Curity Token Handler](https://github.com/curityio/kubernetes-training?tab=readme-ov-file#4---curity-token-handler-example) example deployment.

## 1. Configure Outgoing Logging from the Curity Identity Server

Before deploying the Curity product, edit its [log4j2.xml](https://github.com/curityio/kubernetes-training/blob/main/resources/curity/idsvr-final/log4j2.xml) file.\
Replace default layouts with JSON layouts for the system, request and audit logs.

```xml
<Appenders>
    <Console name="stdout" target="SYSTEM_OUT">
        <JSONLayout compact="true" eventEol="true" properties="true" includeTimeMillis="true">
                <KeyValuePair key="hostname" value="${env:HOSTNAME}" />
        </JSONLayout>
        ...
    </Console>
<Appenders>
```

Use sidecar containers to tail request and audit log files to write them to Kubernetes nodes, ready for log shipping.\
Do so by updating the Helm chart [values.yaml](https://github.com/curityio/kubernetes-training/blob/main/resources/curity/idsvr-final/values.yaml) file.

```yaml
curity:
  runtime:
    logging:
      level: INFO
      image: 'busybox:latest'
      stdout: true
      logs:
      - request
      - audit
...
```

## 2. Configure Incoming Logging into Elastic Search

- An [index template](ingestion/indextemplate.json) helps to ensure the type safety storage of fields in logging events.
- An [ingest pipeline](ingestion/README.md) enables Elasticsearch to transform recived log data to the final JSON format.
- A Kubernetes job runs a [script](ingestion/initdata.sh) to create the index template and the ingest pipeline.

Elasticsearch creates indexes when Filebeat first sends a particular type of log data for a new day.\
Each document in the results has an Elasticsearch index such as `curity-request-2025.03.05`.\
Use Elasticsearch commands to view the index template and ensure that it gets matched to indexes.

```text
GET  /_index_template/curity
POST /_index_template/_simulate_index/curity-request-2025.03.05
```

## 3. Configure Log Shipping

The Filebeat log shipper reads log files from the `/var/log/containers` folder on Kubernetes nodes.\
The log shipper uploads logging events to an Elasticsearch index calculated from the file path and date.\
The following partial configuration shows the approach.

```yaml
filebeat.inputs:
- type: container
  paths:
    - /var/log/containers/curity-idsvr-runtime*audit*.log
    - /var/log/containers/tokenhandler-runtime*-audit*.log
  json:
    keys_under_root: true
    add_error_key: false
  fields:
    logtype: 'audit'

output.elasticsearch:
  hosts: ['${ELASTICSEARCH_HOST:elasticsearch}:${ELASTICSEARCH_PORT:9200}']
  username: ${ELASTICSEARCH_USERNAME}
  password: ${ELASTICSEARCH_PASSWORD}
  index: "curity-%{[fields.logtype]}-%{+yyyy.MM.dd}"
  pipelines:
  - pipeline: curity
```

## 4. Deploy Elastic Stack Components

If you use the example deployment, run the following script to deploy log aggregation components.\
Alternatively, adapt the scripting to match your own deployments.

```bash
./deploy-elastic-stack.sh
```

The script runs a demo deployment of Elasticsearch, Kibana and Filebeat.\
The Kibana frontend uses an external URL of `https://logs.testcluster.example`.\
To make the URL resolvable, get the API gateway's external IP address.

```bash
kubectl get svc -n apigateway
```

Then add the Kibana hostname to any other entries for that IP address in the local computer's `/etc/hosts` file.

```text
172.20.0.5 logs.testcluster.example
```

## 5. Use Kibana for Live Log Analysis

Sign in to Kibana with the following details and access log data from Dev Tools.

- URL: `https://logs.testcluster.example/app/dev_tools#/console`
- User: elastic
- Password: Password1

For example, run Lucene or SQL queries on these indexes to operate on JSON log data.\
You can quickly filter logging events using index fields like an OpenTelemetry trace ID.

```text
GET curity-system*/_search
{ 
  "query":
  {
    "match":
    {
      "contextMap.TraceId": "ce41b85c6f00f167baa53fd814d23c30"
    }
  }
}
```

## Documentation

- See the [Logging Best Practices](https://curity.io/resources/learn/logging-best-practices) article to learn more about Curity Identity Server logs.
- See the [Elasticsearch Tutorial](https://curity.io/resources/learn/log-to-elasticsearch) for a summary of the Elasticsearch integration.

## More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.
