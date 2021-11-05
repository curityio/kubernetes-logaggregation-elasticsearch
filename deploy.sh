#!/bin/bash

###############################################################
# Add Elastic Stack components to a Kubernetes minikube cluster
###############################################################

#
# Deploy Elastic Search in a basic single node setup
# This simple setup destroys all existing data whenever this script is run
#
cd elastic
kubectl delete -f service.yaml 2>/dev/null
kubectl apply -f service.yaml
if [ $? -ne 0 ];
then
  echo "Problem encountered applying ElasticSearch service"
  exit 1
fi

#
# Deploy Kibana and expose it over port 443
#
cd ../kibana
kubectl delete -f service.yaml 2>/dev/null
kubectl apply -f service.yaml
if [ $? -ne 0 ];
then
  echo "Problem encountered applying ElasticSearch service"
  exit 1
fi
kubectl apply -f ingress.yaml