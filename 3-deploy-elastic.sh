#!/bin/bash

#####################################################################################################
# Deploy Elastic Stack components to a Kubernetes minikube cluster, configured to collect Curity logs
#####################################################################################################

#
# Create the Elasticsearch certificate for inside the cluster
#
cd elastic
kubectl delete -f internal-cert.yaml 2>/dev/null
kubectl apply -f internal-cert.yaml
if [ $? -ne 0 ];
then
  echo 'Problem encountered creating ElasticSearch internal certificate'
  exit 1
fi

#
# Deploy Elastic Search in a basic single node setup and expose it over port 443
# This simple setup destroys all existing data whenever this script is run
#
kubectl delete -f service.yaml 2>/dev/null
kubectl apply -f service.yaml
if [ $? -ne 0 ];
then
  echo 'Problem encountered applying ElasticSearch service'
  exit 1
fi
kubectl delete -f ingress.yaml 2>/dev/null
kubectl apply -f ingress.yaml

#
# Create the Kibana certificate for inside the cluster
#
cd ../kibana
kubectl delete -f internal-cert.yaml 2>/dev/null
kubectl apply -f internal-cert.yaml
if [ $? -ne 0 ];
then
  echo 'Problem encountered creating ElasticSearch internal certificate'
  exit 1
fi

#
# Deploy Kibana and expose it over port 443
#
kubectl delete -f service.yaml 2>/dev/null
kubectl apply -f service.yaml
if [ $? -ne 0 ];
then
  echo 'Problem encountered applying ElasticSearch service'
  exit 1
fi
kubectl delete -f ingress.yaml 2>/dev/null
kubectl apply -f ingress.yaml

#
# TODO: Get a pod not in a terminating state
#
#echo 'Waiting for Elasticsearch'
#ELASTIC_POD=$(kubectl get pods | grep elastic | awk '{print $1}')

#
# TODO: Create log schemas
#
cd ../resources

#
# TODO: Create ingestion pipelines
#

#
# TODO: Deploy Filebeat as a Daemonset
#

#
# TODO: Get log aggregation working and deal with log4j2 appenders
#