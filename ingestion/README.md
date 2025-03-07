# Ingesting Logs

The ingest pipeline receives JSON logs that can contain a complex `message` property with multiple key value pairs.\
You can use Elasticsearch [painless scripting](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-scripting-painless.html) to parse incoming logs to the preferred storage format.

## System Logs

The following example shows a system logging event output by the Curity Identity Server in JSON format.\
This example simulates a failed database connection and contains error details:

```json
{
  "timeMillis": 1741275691,
  "thread": "req-189",
  "level": "WARN",
  "loggerName": "se.curity.identityserver.errors.SystemRuntimeException",
  "message": "se.curity.identityserver.errors.SystemRuntimeException@8b67fc[_httpStatus=500,_errorMessageId=system.status.internal.error,_errorCode=generic_error,_errorDescription=FATAL: database \"idsvr2\" does not exist]",
  "endOfBatch": true,
  "loggerFqcn": "org.apache.logging.slf4j.Log4jLogger",
  "contextMap": {
    "LongSessionId": "84aeadea-01cb-4431-bd55-282196a98202",
    "RequestId": "kCPDgMRP",
    "SessionId": "84aeadea",
    "SpanId": "ca8578c5279899bb",
    "TraceId": "2dddaab2003090620ad72cc856b93b9b"
  },
  "threadId": 42,
  "threadPriority": 5,
  "hostname": "curity-idsvr-runtime-6ccbf9799f-rgrrk",
  "timestamp": "2025-03-05T10:03:24.623+0000"
}
```

The [ingest pipeline scripting logic](ingest-pipeline.json) saves the data to the following type-safe format:

```json
{
    "_index": "curity-system-2025.03.05",
    "_id": "FinAZZUBNGGgKy8u4Kq9",
    "_score": 1.0287709,
    "_source": {
      "fields": {
        "logtype": "system"
      },
      "eventTime": 
      "system": {
        "errorCode": "generic_error",
        "errorMessageId": "system.status.internal.error",
        "errorDescription": "FATAL: database idsvr2 does not exist",
        "type": "se.curity.identityserver.errors.SystemRuntimeException@8b67fc",
        "httpStatus": 500
      }
    },
    "_ingest": {
      "pipeline": "curity",
      "timestamp": "2025-03-07T08:35:50.229561138Z"
    }
  }
}
```

In Kibana you can look up details of an HTTP request from a field in the schema, such as an OpenTelemetry trace ID:

```text
GET curity-system*/_search
{ 
  "query":
  {
    "match":
    {
      "contextMap.TraceId": "2dddaab2003090620ad72cc856b93b9b"
    }
  }
}
```

In Kibana Dev Tools, use a [simulation endpoint](https://www.elastic.co/guide/en/elasticsearch/reference/current/simulate-pipeline-api.html) to debug the script and view processor results:

```text
POST /_ingest/pipeline/curity/_simulate?verbose=true
{
  "docs": [
    {
      "_index": "curity-system-2025.03.05",
      "_id": "FinAZZUBNGGgKy8u4Kq9",
      "_source": {
        "fields": {
          "logtype": "system"
        },
        "message": "se.curity.identityserver.errors.SystemRuntimeException@8b67fc[_httpStatus=500,_errorMessageId=system.status.internal.error,_errorCode=generic_error,_errorDescription=FATAL: database \"idsvr2\" does not exist]"
      }
    }
  ]
}
```

## Request Logs

The following example shows a request logging event output by the Curity Identity Server in JSON format:

```json
{
  "timeMillis": 1741168884,
  "thread": "req-171",
  "level": "INFO",
  "loggerName": "se.curity.identityserver.app.RequestReceiver",
  "marker": {
    "name": "REQUEST"
  },
  "message": "accept=\"application/json\" content-type=\"application/json\" duration=\"74\" lang=\"\" method=\"POST\" params=\"\" protocol=\"HTTP/1.1\" secure=\"false\" size=\"1587\" status=\"200\" uri=\"/oauth/v2/oauth-token\"",
  "endOfBatch": true,
  "loggerFqcn": "org.apache.logging.log4j.spi.AbstractLogger",
  "contextMap": {
    "RequestId": "yK0nYfVW",
    "SpanId": "90a3f360f1a7112c",
    "TraceId": "ce41b85c6f00f167baa53fd814d23c30"
  },
  "threadId": 42,
  "threadPriority": 5,
  "hostname": "curity-idsvr-runtime-65bddfd64f-cqm7s",
  "timestamp": "2025-03-05T10:01:24.623+0000"
}
```

The [ingest pipeline scripting logic](ingest-pipeline.json) saves the data to the following type-safe format:

```json
{
  "_index": "curity-request-2025.03.05",
  "_id": "FinAZZUBNGGgKy8u4Kq8",
  "_score": 2.1282315,
  "_source": {
    "loggerFqcn": "org.apache.logging.log4j.spi.AbstractLogger",
    "level": "INFO",
    "thread": "req-171",
    "message": "",
    "threadPriority": 5,
    "threadId": 42,
    "hostname": "curity-idsvr-runtime-65bddfd64f-cqm7s",
    "@timestamp": "2025-03-05T10:01:24.735Z",
    "request": {
      "duration": 74,
      "protocol": "HTTP/1.1",
      "method": "POST",
      "size": 1587,
      "content-type": "application/json",
      "lang": "",
      "params": "",
      "secure": "false",
      "uri": "/oauth/v2/oauth-token",
      "accept": "application/json",
      "status": 200
    },
    "contextMap": {
      "RequestId": "yK0nYfVW",
      "TraceId": "ce41b85c6f00f167baa53fd814d23c30",
      "SpanId": "90a3f360f1a7112c"
    },
    "loggerName": "se.curity.identityserver.app.RequestReceiver",
    "timestamp": "2025-03-05T10:01:24.623+0000"
  }
}
```

In Kibana you can look up details of an HTTP request from a field in the schema, such as an OpenTelemetry trace ID:

```text
GET curity-request*/_search
{ 
  "query":
  {
    "match":
    {
      "contextMap.TraceId": "ce41b85c6f00f167baa53fd814d23c30"
    }
  }
}
```

In Kibana Dev Tools, use a [simulation endpoint](https://www.elastic.co/guide/en/elasticsearch/reference/current/simulate-pipeline-api.html) to debug the script and view processor results:

```text
POST /_ingest/pipeline/curity/_simulate?verbose=true
{
  "docs": [
    {
      "_index": "curity-request-2025.03.05",
      "_id": "FinAZZUBNGGgKy8u4Kq9",
      "_source": {
        "fields": {
          "logtype": "request"
        },
        "message": "accept=\"application/json\" content-type=\"application/json\" duration=\"74\" lang=\"\" method=\"POST\" params=\"\" protocol=\"HTTP/1.1\" secure=\"false\" size=\"1587\" status=\"200\" uri=\"/oauth/v2/oauth-token\""
      }
    }
  ]
}
```

## Audit Logs

The following example shows an audit logging event output by the Curity Identity Server in JSON format:

```json
{
  "timeMillis": 1741168884,
  "thread": "req-171",
  "level": "INFO",
  "loggerName": "audit-events",
  "message": "access-token-issued [923cc315729340008510706b01990d8a authenticatedClient=\"spa-client\" authenticatedSubject=\"johndoe\" client=\"spa-client\" instant=\"2025-03-05T10:01:24.615014186Z\" server=\"CnxNuqLW\" subject=\"3b5aba986d28551691bf94caff6a29466f521c47365aee02e67517157d25d4c8\"] Access token issued for subject \"3b5aba986d28551691bf94caff6a29466f521c47365aee02e67517157d25d4c8\" with client \"spa-client\"",
  "endOfBatch": true,
  "loggerFqcn": "org.apache.logging.log4j.spi.AbstractLogger",
  "contextMap": {
    "RequestId": "yK0nYfVW",
    "SpanId": "90a3f360f1a7112c",
    "TraceId": "ce41b85c6f00f167baa53fd814d23c30"
  },
  "threadId": 42,
  "threadPriority": 5,
  "hostname": "curity-idsvr-runtime-65bddfd64f-cqm7s",
  "timestamp": "2025-03-05T10:01:24.615+0000"
}
```

The [ingest pipeline scripting logic](ingest-pipeline.json) saves the data to the following type-safe format:

```json
{
  "_index": "curity-audit-2025.03.05",
  "_id": "NynBZZUBNGGgKy8uCarZ",
  "_score": 0.83624804,
  "_source": {
    "loggerFqcn": "org.apache.logging.log4j.spi.AbstractLogger",
    "level": "INFO",
    "thread": "req-171",
    "message": "",
    "threadPriority": 5,
    "threadId": 42,
    "hostname": "curity-idsvr-runtime-65bddfd64f-cqm7s",
    "@timestamp": "2025-03-05T10:01:25.266Z",
    "audit": {
      "server": "CnxNuqLW",
      "authenticatedSubject": "johndoe",
      "subject": "3b5aba986d28551691bf94caff6a29466f521c47365aee02e67517157d25d4c8",
      "client": "spa-client",
      "id": "923cc315729340008510706b01990d8a",
      "type": "access-token-issued",
      "authenticatedClient": "spa-client",
      "instant": "2025-03-05T10:01:24.615014186Z"
    },
    "loggerName": "audit-events",
    "contextMap": {
      "RequestId": "yK0nYfVW",
      "TraceId": "ce41b85c6f00f167baa53fd814d23c30",
      "SpanId": "90a3f360f1a7112c"
    },
    "timestamp": "2025-03-05T10:01:24.615+0000"
  }
}
```

In Kibana you can look up an audit document from a field in the schema, such as an OpenTelemetry trace ID:

```text
GET curity-audit*/_search
{ 
  "query":
  {
    "match":
    {
      "contextMap.TraceId": "ce41b85c6f00f167baa53fd814d23c30"
    }
  }
}
```

In Kibana Dev Tools, runs a command like this to debug the script and view processor results:

```text
POST /_ingest/pipeline/curity/_simulate?verbose=true
{
  "docs": [
    {
      "_index": "curity-audit-2025.03.05",
      "_id": "FinAZZUBNGGgKy8u4Kq9",
      "_source": {
        "fields": {
          "logtype": "request"
        },
        "message": "access-token-issued [923cc315729340008510706b01990d8a authenticatedClient=\"spa-client\" authenticatedSubject=\"johndoe\" client=\"spa-client\" instant=\"2025-03-05T10:01:24.615014186Z\" server=\"CnxNuqLW\" subject=\"3b5aba986d28551691bf94caff6a29466f521c47365aee02e67517157d25d4c8\"] Access token issued for subject \"3b5aba986d28551691bf94caff6a29466f521c47365aee02e67517157d25d4c8\" with client \"spa-client\""
      }
    }
  ]
}
```