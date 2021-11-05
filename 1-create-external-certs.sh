#!/bin/bash

############################################################################
# This script creates external ingress certificates for the two public URLs:
# - https://logs.curity.local for Kibana
# - https://api.logs.curity.local for Elasticsearch
############################################################################

mkdir -p certs
cd certs
set -e

#
# Point to the OpenSSL configuration file for macOS or Windows
#
case "$(uname -s)" in

  Darwin)
    export OPENSSL_CONF='/System/Library/OpenSSL/openssl.cnf'
 	;;

  MINGW64*)
    export OPENSSL_CONF='C:/Program Files/Git/usr/ssl/openssl.cnf';
    export MSYS_NO_PATHCONV=1;
	;;
esac

#
# Certificate properties
#
ROOT_CERT_FILE_PREFIX='curitylogs.ca'
ROOT_CERT_DESCRIPTION='Self Signed CA for curitylogs.local'
SSL_CERT_FILE_PREFIX='curitylogs.local.ssl'
SSL_CERT_PASSWORD='Password1'
WILDCARD_DOMAIN_NAME='*.curitylogs.local'

#
# Create the root certificate public + private key
#
echo 'Creating external certificates for Elasticsearch and Kibana ...'
openssl genrsa -out $ROOT_CERT_FILE_PREFIX.key 2048

#
# Create the public key root certificate file
#
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
# Create the SSL key
#
openssl genrsa -out $SSL_CERT_FILE_PREFIX.key 2048

#
# Create the certificate signing request file
#
openssl req \
            -new \
			-key $SSL_CERT_FILE_PREFIX.key \
			-out $SSL_CERT_FILE_PREFIX.csr \
			-subj "/CN=$WILDCARD_DOMAIN_NAME"

#
# Create the SSL certificate and private key
#
openssl x509 -req \
			-in $SSL_CERT_FILE_PREFIX.csr \
			-CA $ROOT_CERT_FILE_PREFIX.pem \
			-CAkey $ROOT_CERT_FILE_PREFIX.key \
			-CAcreateserial \
			-out $SSL_CERT_FILE_PREFIX.pem \
			-sha256 \
			-days 36 \
      -extfile server.ext

#
# Create a Kubernetes secret for our test SSL certificates, which is referenced in the ingress
#
kubectl delete secret curitylogs-local-tls 2>/dev/null
kubectl create secret tls curitylogs-local-tls --cert=./certs/curitylogs.local.ssl.pem --key=./certs/curitylogs.local.ssl.key

#
# Indicate success
#
echo 'All external certificates created successfully'
