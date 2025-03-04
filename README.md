# Curity Identity Server Log Aggregation to Elastic Search

An example repository to demonstrate aggregation of the following logs and to include OpenTelemetry trace and span IDs:

- System logs
- Request logs
- Audit logs

## Prerequisites

Start with base deployments such as the following examples:

- The [Curity Identity Server](https://github.com/curityio/kubernetes-training?tab=readme-ov-file#3---curity-identity-server-example) example deployment from the Kubernetes Training repository.
- The [Curity Token Handler](https://github.com/curityio/kubernetes-training?tab=readme-ov-file#4---curity-token-handler-example) example deployment from the Kubernetes Training repository.

## 1. Configure Outgoing Logging from the Curity Identity Server

Before deploying the Curity product, edit the [log4j2.xml](https://github.com/curityio/kubernetes-training/blob/main/resources/curity/idsvr-final/log4j2.xml) file and activate a JSON layout for the system, request and audit logs.\
Also remove the default layouts so that appenders look similar to this:

```xml
<Appenders>
    <Console name="stdout" target="SYSTEM_OUT">
        <JSONLayout compact="true" eventEol="true" properties="true" stacktraceAsString="true">
            <KeyValuePair key="logtype" value="system" />
            <KeyValuePair key="hostname" value="${env:HOSTNAME}" />
            <KeyValuePair key="timestamp" value="$${date:yyyy-MM-dd'T'HH:mm:ss.SSSZ}" />
        </JSONLayout>
        ...
    </Console>
<Appenders>
```

Next activate sidecar containers to tail request and audit log files to write them to Kubernetes nodes, ready for log shipping.\
Do so by updating the Helm chart [values.yaml](https://github.com/curityio/kubernetes-training/blob/main/resources/curity/idsvr-final/values.yaml) file:

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

In Elasticsearch, index templates define storage of logging events as type-safe JSON documents:

- [System Logs Index Template](logs/ingestion/indextemplate-curity-system.json)
- [Request Logs Index Template](logs/ingestion/indextemplate-curity-request.json)
- [Audit Logs Index Template](logs/ingestion/indextemplate-curity-audit.json)

An [ingest pipeline](logs/ingestion/ingest-pipeline-template.json) uses some [scripting](logs/ingestion/script-processor.txt) to ensure clean JSON log data.\
A Kubernetes job runs a [script](logs/initdata.sh) to import these resources into Elasticsearch.

## 3. Configure Log Shipping

The Filebeat log shipper reads log files from the `/var/log/containers` folder on Kubernetes nodes.\
The log shipper uploads logging events and determines the index from a fixed field `logtype` from the logging event.

```yaml
filebeat.inputs:
- type: container
  paths:
    - /var/log/containers/curity-idsvr-runtime*.log
    - /var/log/containers/tokenhandler-runtime*.log
  json:
    keys_under_root: true
    add_error_key: false

output.elasticsearch:
  hosts: ['${ELASTICSEARCH_HOST:elasticsearch}:${ELASTICSEARCH_PORT:9200}']
  username: ${ELASTICSEARCH_USERNAME}
  password: ${ELASTICSEARCH_PASSWORD}
  index: "curity-%{[fields.logtype]:system}-%{+yyyy.MM.dd}"
  pipelines:
  - pipeline: curity-ingest-pipeline

setup.ilm.enabled: false
setup.template.name: curity
setup.template.pattern: curity-*

processors:
- drop_fields:
    fields: ['agent', 'ecs', 'host', 'input', 'version']
```

## 4. Deploy Elastic Stack Components

If you use the example deployments referenced at the top of this page, run the following script to extend the system.\
Alternatively, adapt the scripting to match your own cluster.

```bash
./deploy-elastic-stack.sh
```

The script adds a demo deployment of Elasticsearch, Kibana and Filebeat to the Kubernetes cluster:
An external URL for Kibana runs at `https://logs.testcluster.example`.\
To make the URL resolvable, get the API gateway's external IP address:

```bash
kubectl get svc -n apigateway
```

Then map the Kibana hostname to any other entries for that IP address in the local computer's `/etc/hosts` file:

```text
172.20.0.5 logs.testcluster.example
```

## 5. Run Live Analysis

Sign in to Kibana using the following credentials:

- URL: `https://logs.testcluster.example/app/dev_tools#/console`
- User: elastic
- Password: Password1

Then access logs in close to real time, to enable the best troubleshooting and analysis.\
For example, run Lucene or SQL queries to operate on the log data and filter on fields in the JSON log data:

```bash
GET curity-system*/_search
GET curity-request*/_search
GET curity-audit*/_search
```

## Documentation

- See the [Logging Best Practices](https://curity.io/resources/learn/logging-best-practices) article to learn more about Curity Identity Server logs.
- See the [Elasticsearch Tutorial](https://curity.io/resources/learn/log-to-elasticsearch) for a summary of Elasticsearch integration.

## More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.
