# Kubernetes Log Aggregation to Elasticsearch

Demonstrates how to aggregate logs from the Curity Identity Server and then query results.

## Components

The following Elastic components are used:

| Component | URL | Behavior |
| --------- | --- | -------- |
| Elasticsearch | http://api.elastic.local | The main Elasticsearch component including API and data storage |
| Kibana | http://elastic.local | A Browser UI for querying logs for the whole cluster field by field |
| Filebeat | N/A | A component that ships JSON logs to the Elasticsearch API |

## Prerequisites

Clone the [Kubernetes Quick Start GitHub repository](https://github.com/curityio/kubernetes-quick-start) and deploy the base system, following the [Tutorial Documentation](https://curity.io/resources/learn/kubernetes-demo-installation/).\

## Configuration Updates

Once working, edit the `helm-values.yaml` file to activate tailing of request logs:

```yaml
  runtime:
    logging:
      image: "busybox:latest"
      level: INFO
      stdout: true
      logs:
      - request
#        - audit
#        - cluster
#        - confsvc
#        - confsvc-internal
#        - post-commit-scripts
```

Also update the appenders in the `log4j2.xml` file to use JSONLayout, replacing the default PatternLayout.\
Each log entry is then a bare JSON line that log shippers can easily consume.

```xml
<Appenders>
    <Console name="stdout" target="SYSTEM_OUT">
        <JSONLayout compact="true" eventEol="true" properties="true" stacktraceAsString="true">
            <KeyValuePair key="hostname" value="${env:HOSTNAME}" />
            <KeyValuePair key="timestamp" value="$${date:yyyy-MM-dd'T'HH:mm:ss.SSSZ}" />
        </JSONLayout>
        <filters>
            <MarkerFilter marker="REQUEST" onMatch="DENY" onMismatch="NEUTRAL"/>
            <MarkerFilter marker="EXTENDED_REQUEST" onMatch="DENY" onMismatch="NEUTRAL"/>
        </filters>
    </Console>
    <RollingFile name="request-log" fileName="${env:IDSVR_HOME}/var/log/request.log"
                    filePattern="${env:IDSVR_HOME}/var/log/request.log.%i.gz">
        <JSONLayout compact="true" eventEol="true" properties="true" stacktraceAsString="true">
            <KeyValuePair key="hostname" value="${env:HOSTNAME}" />
            <KeyValuePair key="timestamp" value="$${date:yyyy-MM-dd'T'HH:mm:ss.SSSZ}" />
        </JSONLayout>
        <Policies>
            <SizeBasedTriggeringPolicy size="10MB"/>
        </Policies>
        <DefaultRolloverStrategy max="5"/>
        <filters>
            <MarkerFilter marker="EXTENDED_REQUEST" onMatch="ACCEPT" onMismatch="NEUTRAL"/>
            <MarkerFilter marker="REQUEST" onMatch="ACCEPT" onMismatch="DENY"/>
        </filters>
    </RollingFile>
</Appenders>
```

Next re-run the `deploy-idsvr.sh` script, to apply the above settings.

## Deploy Elastic Components

Run `minikube ip --profile curity` to get the virtual machine's IP address.\
Ensure that Elasticsearch related domain names are mapped to the IP address in the `hosts` file on the local computer:

```bash
192.168.64.3   login.curity.local admin.curity.local api.elastic.local elastic.local
```

Run the first script to deploy Elasticsearch and Kibana:

```bash
./1-deploy-elastic.sh
```

Then run the second script to deploy log shipping configurations and then the filebeat component:

```bash
./2-deploy-log-shipping.sh
```

## Query Curity Logs

Run an example app to generate logs, then navigate to the [Kibana System](http://elastic.local/app/dev_tools#/console).\
Sign in as `elastic / Password1` then query logs across all runtime nodes field by field:

```sql
POST _sql?format=txt
{
  "query": "select right(hostname, 5) as host, contextMap.RequestId as requestID, contextMap.SessionId as sessionID, http.method, http.uri, http.status, http.duration from \"curityrequest*\" order by http.duration desc limit 20"
}
```

![Initial Query](/images/example-query.png)

You can also connect to the Elasticsearch API via REST request to query data by schema:

```bash
curl -u 'elastic:Password1' http://api.elastic.local/curitysystem/_search | jq
```

## Documentation

- See the [Logging Best Practices](https://curity.io/resources/learn/logging-best-practices) article for the recommended techniques
- See the [Elasticsearch Tutorial](https://curity.io/resources/learn/log-to-elasticsearch) for a walkthrough of using this GitHub repository

## Free Resources

Run the following command to tear down the Kubernetes cluster and free all resources:

```bash
minikube delete --profile curity
```

## More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.
