#!/bin/bash

################################################################################################
# The example uses Kibana with user logins, which requires use of TLS between Elastic and Kibana
# Therefore we use cert manager to automatically issue certificates for inside the cluster
################################################################################################

mkdir -p certs
cd certs

#
# Point to the OpenSSL configuration file for the platform
#
case "$(uname -s)" in

  # Mac OS
  Darwin)
    export OPENSSL_CONF='/System/Library/OpenSSL/openssl.cnf'
 	;;

  # Windows with Git Bash
  MINGW64*)
    export OPENSSL_CONF='C:/Program Files/Git/usr/ssl/openssl.cnf';
    export MSYS_NO_PATHCONV=1;
	;;
esac

#
# Create a Root CA that certmanager will use to automatically issue certificates inside the cluster
#
echo 'Creating a root certificate authority for inside the cluster ...'
ROOT_CERT_FILE_PREFIX='cluster.ca'
ROOT_CERT_DESCRIPTION='Self Signed CA for svc.default.cluster.local'
openssl genrsa -out $ROOT_CERT_FILE_PREFIX.key 2048
openssl req -x509 \
            -new \
            -nodes \
            -key $ROOT_CERT_FILE_PREFIX.key \
            -out $ROOT_CERT_FILE_PREFIX.pem \
            -subj "/CN=$ROOT_CERT_DESCRIPTION" \
            -reqexts v3_req \
            -extensions v3_ca \
            -sha256 \
            -days 365

#
# Deploy a secret for the root CA for certificates used inside the cluster
#
echo 'Deploying the root certificate authority to the cluster ...'
kubectl delete secret clusterca 2>/dev/null
kubectl create secret tls clusterca --cert=./cluster.ca.pem --key=./cluster.ca.key
if [ $? -ne 0 ]
then
  echo "*** Problem creating secret for internal root certificate authority ***"
  exit 1
fi

#
# Next deploy certificate manager, used to issue certificates for inside the cluster
# Then do 'kubectl get all -n cert-manager' to see installed components
#
echo 'Downloading certificate manager ...'
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.yaml
if [ $? -ne 0 ]
then
  echo "*** Problem encountered downloading certmanager"
  exit 1
fi

#
# Wait for cert manager to initialize as described here, so that our root cluster certificate is trusted
# https://github.com/jetstack/cert-manager/issues/3338#issuecomment-707579834
#
echo "Waiting for certmanager cainjector to initialize ..."
sleep 30

#
# Next deploy a cluster issuer that references the above secret called 'clusterca'
# This can be used to issue internal SSL certificates whenever an Elasticsearch pod is spun up
# See elastic/internal-cert for how the issuer is used
#
echo 'Creating a cluster issuer to issue internal certificates when pods are created ...'
kubectl apply -f ./clusterIssuer.yaml
if [ $? -ne 0 ]
then
  echo "*** Problem creating the certmanager cluster issuer"
  exit 1
fi

#
# Indicate success
#
echo 'All internal certificates created successfully'
exit 0