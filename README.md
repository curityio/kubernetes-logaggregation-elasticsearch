# Kubernetes Log Aggregation to Elasticsearch

A repo to show how to aggregate logs from the Curity Identity Server and then query results.

## Components

The following Elastic components are used:

| Component | URL | Behavior |
| --------- | --- | -------- |
| Elasticsearch | http://api.elastic.local | The main Elasticsearch component including API and data storage |
| Kibana | http://elastic.local | A Browser UI for querying logs for the whole cluster field by field |
| Filebeat | N/A | A component that ships JSON logs to the Elasticsearch API |

## Prerequisites

Clone the [Kubernetes Quick Start GitHub repository](https://github.com/curityio/kubernetes-quick-start) and follow the [Tutorial Documentation](https://curity.io/resources/learn/kubernetes-demo-installation/).\
When creating the cluster, ensure sufficient resources for the Elastic components by using these values:

```bash
minikube start --cpus=4 --memory=16384 --disk-size=50g --driver=hyperkit --profile curity
```

## Deploy Elastic Components

Run `minikube ip --profile curity` to get the virtual machine's IP address.\
Then add these domains against the IP address in the `hosts` file on the local computer:

```bash
192.168.64.4   login.curity.local admin.curity.local api.elastic.local elastic.local
```

Run the first script to deploy Elasticsearch and Kibana:

```bash
./1-deploy-elastic.sh
```

Then run the second script to deploy log shipping configurations and the filebeat component:

```bash
./2-deploy-log-shipping.sh
```

## Query Curity Logs

Run an example app to generate logs, then navigate to the [Kibana System](http://elastic.local/app/dev_tools#/console).\
Sign in as `elastic / Password1` then query logs across all runtime nodes field by field:

![Initial Query](/images/initial-query.png)

You can also connect to the Elasticsearch API via REST request to query data by schema:

```bash
curl -u 'elastic:Password1' http://api.elastic.local/curitysystem/_search | jq
```

## Documentation

- See the [Logging Best Practices](https://curity.io/resources/learn/logging-best-practices) article for the recommended techniques
- See the [Elasticsearch Tutorial](https://curity.io/resources/learn/log-to-elasticsearch) for a walkthrough of Elasticsearch as an example implementation

## Free Resources

Run the following command to tear down the Kubernetes cluster and free all resources:

```bash
minikube delete --profile curity
```

## More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.
