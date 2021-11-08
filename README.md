# Aggregation of Curity Logs to Elasticsearch

A repo to show how to aggregate logs from the Curity Identity Server and then query results.

## Components

The following Elastic components are used:

| Component | URL | Behavior |
| --------- | --- | -------- |
| Elasticsearch | https://api.curitylogs.local | The main Elasticsearch component including API and data storage |
| Filebeat | N/A | A component that sends Curity Identity Server logs to the Elasticsearch API |
| Kibana | https://curitylogs.local | A UI used to query logs field by field and to set filters |

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
192.168.64.4   api.curitylogs.local curitylogs.local
```

Run the first script to create certificates for the Elasticsearch and Kibana public URLs:

```bash
./1-create-certs.sh
```

Then run this script to deploy the Elastic components:

```bash
./2-deploy-elastic.sh
```

This creates Elasticsearch schemas and ingestion pipelines ready to receive data.

## Run an Example App

Use the HAAPI code example from the Kubernetes Demo Installation to generate some logs:

| Field | Value |
| ----- | ----- |
| URL | https://login.curity.local/demo-client.html |
| User | demouser |
| Password | Password1 |

![Example App](/images/example-app.png)

## Query Curity Logs

Navigate to the [Kibana System](https://curitylogs.local/app/dev_tools#/console), sign in as `elastic / Password1` then query logs field by field:

![Initial Query](/images/initial-query.png)

You can also connect to the Elasticsearch API via a REST request to perform filtered exports:

```bash
curl -k -u 'elastic:Password1' https://api.curitylogs.local
```

## Documentation

- See the [Logging Best Practices](https://curity.io/resources/learn/authenticate-with-google-authenticator/) article for the recommended techniques
- See the [Elasticsearch Tutorial](https://curity.io/resources/learn/elasticsearch-tutorial/) for a walkthrough of Elasticsearch as an example implementation

## Free Resources

Run the following command to tear down the Kubernetes cluster and free all resources:

```bash
minikube delete --profile curity
```

## More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.
