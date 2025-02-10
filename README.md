# Kubernetes Log Aggregation to Elasticsearch

Demonstrates how to aggregate logs from the Curity Identity Server and then query results.

## Prepare the Curity Identity Server

Prepare a base cluster such as the `Curity Identity Server` deployment from the [Kubernetes Training](https://github.com/curityio/kubernetes-quick-start) repository.\
Before running the deployment, update the Helm `values.yaml` file to create extra sidecars to tail logs.\
The following example does so for request logs written to file on the Curity Identity Server runtime containers.

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

Also update appenders in the `log4j2.xml` file to use JSONLayout, replacing the default PatternLayout.

```xml
<Appenders>
    <Console name="stdout" target="SYSTEM_OUT">
        <JSONLayout compact="true" eventEol="true" properties="true" stacktraceAsString="true">
            <KeyValuePair key="hostname" value="${env:HOSTNAME}" />
            <KeyValuePair key="timestamp" value="$${date:yyyy-MM-dd'T'HH:mm:ss.SSSZ}" />
        </JSONLayout>
        ...
    </Console>
    <RollingFile name="request-log" fileName="${env:IDSVR_HOME}/var/log/request.log"
                    filePattern="${env:IDSVR_HOME}/var/log/request.log.%i.gz">
        <JSONLayout compact="true" eventEol="true" properties="true" stacktraceAsString="true">
            <KeyValuePair key="hostname" value="${env:HOSTNAME}" />
            <KeyValuePair key="timestamp" value="$${date:yyyy-MM-dd'T'HH:mm:ss.SSSZ}" />
        </JSONLayout>
        ...
    </RollingFile>
</Appenders>
```

## Deploy Elastic Components

Run the first script to deploy Elasticsearch and Kibana:

```bash
./1-deploy-elastic.sh
```

Then run the second script to deploy log shipping configurations and then the Filebeat component:

```bash
./2-deploy-log-shipping.sh
```

By default the scripts expose components from the cluster at the following URLs:

- Kibana runs at `http://elastic.local`
- Elasticsearch runs at `http://api.elastic.local`

To make these URLs resolvable, get the external IP address:

```bash
kubectl get svc -A
```

Then add domains to the local computer's `/etc/hosts` file:

```text
172.20.0.5 elastic.local api.elastic.local
```

## Query Curity Logs

Sign in and access the Kibana DevTools using these URLs:

- URL: http://elastic.local/app/dev_tools#/console
- User: elastic
- Password: Password1

Then use queries to analyze logs from all runtime workloads of the Curity Identity Server:

```sql
POST _sql?format=txt
{
  "query": "select right(hostname, 5) as host, contextMap.RequestId as requestID, contextMap.SessionId as sessionID, http.method, http.uri, http.status, http.duration from \"curityrequest*\" order by http.duration desc limit 20"
}
```

![Initial Query](/images/example-query.png)

## Documentation

- See the [Logging Best Practices](https://curity.io/resources/learn/logging-best-practices) article for details on techniques
- See the [Elasticsearch Tutorial](https://curity.io/resources/learn/log-to-elasticsearch) for further information about Elasticsearch integration

## More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.
