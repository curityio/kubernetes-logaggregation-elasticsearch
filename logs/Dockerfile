FROM alpine:latest
RUN apk add --update curl bash

WORKDIR          /usr/job
COPY ingestion   /usr/job/ingestion
COPY initdata.sh /usr/job

SHELL ["/bin/bash", "-c"]
ENTRYPOINT ./initdata.sh
