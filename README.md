# Aggregation of Curity Logs to Elasticsearch

A repo to show how to aggregate logs from the Curity Identity Server and then query results.

## Components

The following Elastic components are used:

| Component | URL | Behavior |
| --------- | --- | -------- |
| Elasticsearch | https://api.curitylogs.local | The main Elasticsearch component including API and data storage |
| Filebeat | N/A | A component that sends Curity Identity Server logs to the Elasticsearch API |
| Kibana | https://curitylogs.local | A UI used to query logs field by field and to set filters |

## Log Usage

Run scripts then connect to the Elasticsearch service like this:

```bash
curl -k -u 'elastic:Password1' https://api.curitylogs.local
```

Navigate to Kibana at https://curitylogs.local and sign in as `elastic / Password1`.\
Then query Curity logs from the entire cluster field by field:

![Dev Tools](/images/devtools.png)

Results of a filtered query can be exported via this command, such as to send to Curity:

- TODO

## Prerequisites

First run the [Kubernetes Demo Installation](https://curity.io/resources/learn/kubernetes-demo-installation/).\
Clone its [GitHub repository](https://github.com/curityio/kubernetes-quick-start) and ensure sufficient resources:

```bash
minikube start --cpus=4 --memory=16384 --disk-size=50g --driver=hyperkit --profile curity
```

## Elastic Components Setup

Run `minikube ip --profile curity` to get the minikube virtual machine's IP address.\
Then add entries like this to the `hosts` file on the local computer:

```bash
192.168.64.4   api.curitylogs.local curitylogs.local
```

Run the first script to create certificates for external URLs:

```bash
./1-create-external-certs.sh
```

In order to use Kibana logins via user name and password, SSL must also be used inside the cluster.\
Run the following script to use [certmanager](https://cert-manager.io/docs/) to issue these certificates:

```bash
./2-create-internal-certs.sh
```

Then run this script to deploy and configure the Elastic components:

```bash
3-deploy-elastic.sh
```

## Documentation

- See the [Logging Best Practices](https://curity.io/resources/learn/authenticate-with-google-authenticator/) article for the recommended techniques
- See the [Elasticsearch Tutorial](https://curity.io/resources/learn/elasticsearch-tutorial/) for a walkthrough of using this repository

## Free Resources

Run the following command to tear down the Kubernetes cluster and free all resources:

```bash
minikube delete --profile curity
```

## More Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.