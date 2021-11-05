# Log Aggregation with the Elastic Stack

A repo to show how to aggregate logs from the Curity Identity Server and then query results.

## Usage

This GitHub repository extends the [Kubernetes Demo Installation](https://curity.io/resources/learn/kubernetes-demo-installation/) to use log aggregation.\
The Kibana tool can then be used to query logs for the Curity Identity Server on a field by field basis:

SCREENSHOT

## Prerequisites

First run the [Kubernetes Demo Installation](https://curity.io/resources/learn/kubernetes-demo-installation/).
Edit the `create-cluster.sh` script in the [GitHub repository](https://github.com/curityio/kubernetes-quick-start) to ensure sufficient resources:

```bash
minikube start --cpus=4 --memory=16384 --disk-size=50g --driver=hyperkit --profile curity
```

Also include the `logs.curity.local` domain name when updating the hosts file:

```bash
192.168.64.54  login.curity.local admin.curity.local logs.curity.local
```

## Deploy Elastic Components

Run the following script to deploy Elastic Search, Kibana and Filebeat components.\
This may take a few minutes since it downloads some large Docker images:

```bash
./deploy.sh
```

## Run the HAAPI Code Example

Run the HAAPI code example to generate some log activity:

## Query Logs via Kibana

Browse to https://logs.curity.local and log in to Kibana with credentials `admin / Password1`:

## Internal URLs

The URLs inside the cluster can be tested as follows:

```bash
ELASTIC_POD=$(kubectl get pods | grep elastic | awk '{print $1}')
kubectl exec -it $ELASTIC_POD -- bash -c 'curl http://localhost:9200'
```

```bash
KIBANA_POD=$(kubectl get pods | grep kibana | awk '{print $1}')
kubectl exec -it $KIBANA_POD -- bash -c 'curl http://localhost:5601'
```
## Filebeat Aggregation

A few notes on how Filebeat translates logs to JSON documents

## Understand Logging Best Practices

We recommend use of an appender to redirect system logs from `stdout` to a file:

MORE TO GO HERE

## Free Resources

Run the following command to tear down the Kubernetes cluster and free all resources:

```bash
minikube delete --profile curity
```

## More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.