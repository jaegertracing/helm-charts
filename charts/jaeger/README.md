# Jaeger Helm Chart

> ⚠️ **Experimental**: This chart is under active development with no stability guarantees. Breaking changes may occur in minor versions.

[Jaeger](https://www.jaegertracing.io/) is a distributed tracing system. This chart deploys Jaeger v2 using a unified "All-In-One" architecture built on the OpenTelemetry Collector framework.

## Changes in v4.2.0

This release is a refactor designed to simplify operation and configuration.

- **Unified Architecture**: All functionality (Collector, Query, Ingester) is now provided by a single "All-in-One" deployment.
- **Configuration**: Storage is configured via the `config.extensions.jaeger_storage` section using native Jaeger/OTEL config syntax.
- **Cassandra Schema**: Jaeger v2 handles schema creation internally. The legacy schema job has been removed.
- **Service Consolidation**: A single Service now exposes all ports (agent, collector, query).
- **No provisioned storage**: Dependency charts have been removed.  The user must deploy them separately and configure connection using the Otel config Syntax https://github.com/jaegertracing/jaeger/blob/main/cmd/jaeger/config.yaml 

## Architecture

This chart uses the **All-In-One** deployment model.
- **Single Binary**: Runs as a `Deployment` scalable to multiple replicas.
- **Stateless**: Can connect to external persistent storage (Elasticsearch, Cassandra) for production use.
- **Default**: Memory storage (ephemeral), suitable for testing.
- **Scalable**: Increase replica count to scale horizontally

## Overriding the Jaeger Version 
##### (chart only supports Jaever v2+)

You can customize the Jaeger image and tag using the following values:

```yaml
jaeger:
  image:
    repository: jaegertracing/jaeger
    tag: "2.2.0"  # Override the default version
```

Or globally:
```yaml
tag: "2.2.0"  # Applies to all components
```

## Installing the Chart

Add the Jaeger Tracing Helm repository:
```bash
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
```

To install a release named `jaeger`:
```bash
helm install jaeger jaegertracing/jaeger
```

## Configuration

There are several examples of how to configure you can reference at:

https://github.com/jaegertracing/jaeger/tree/main/cmd/jaeger

### 1. In-Memory (Default)
Ideal for testing. No persistence.
```bash
helm install jaeger jaegertracing/jaeger
```

### 2. Elasticsearch (Production Recommended)

This chart does not provision an ElasticSearch instance.

To use ElasticSearch storage, you must provide your own ElasticSearch instance and configure Jaeger via the native config syntax:

#### Elasticsearch example:

**values.yaml**
```yaml
userconfig:
  extensions:
    jaeger_query:
      storage:
        traces: primary_store_elasticsearch
        traces_archive: archive_store_elasticsearch
    jaeger_storage:
      backends:
        primary_store_elasticsearch:
          elasticsearch:
            server_urls: ["http://my-elasticsearch-master:9200"]
            auth:
              basic:
                username: elastic
                password: changeme
        archive_store_elasticsearch:
          elasticsearch:
            server_urls: ["http://my-elasticsearch-master:9200"]
            auth:
              basic:
                username: elastic
                password: changeme
  exporters:
    jaeger_storage_exporter:
      trace_storage: primary_store_elasticsearch
```

**Running Maintenance Jobs:**

To run Index Cleaner or Rollover jobs, enable them. 
They require configuration by adjusting ```storage.elasticsearch``` values.  See that section in values.yaml for more details.

```yaml
esIndexCleaner:
  enabled: true

storage:
  elasticsearch:
    tls:
      enabled: false
    url: http://elasticsearch-master:9200
    # user: elastic
    # password: changeme
```

* es-rollover __requires__ elasticsearch to be running __BEFORE__ install so the hook job can run.

### 3. Cassandra
This chart does not provision a Cassandra cluster.

To use Cassandra storage, you must provide your own Cassandra instance and configure Jaeger via the native config syntax:

**values.yaml Example:**
```yaml
storage:
  type: cassandra

config:
  extensions:
    jaeger_storage:
      backends:
        primary_store:
          cassandra:
            connection:
              servers:
                - cassandra-host
              port: 9042
            schema:
              keyspace: jaeger_v1_test
```

> **Note**: The legacy Cassandra schema job has been removed. Jaeger v2 handles schema creation internally.

### 4. Spark Dependencies

To run the Spark dependencies job (for dependency links graph) set ```spark.enabled=true```

Below is an example of how to set overrides.  Please see the values.yaml for more examples:

The values are populated under ```storage.elasticsearch``` and ```storage.casandra``` Please see comments in values.yaml for more details.

You must choose the storage type with ```storage.type=elasticsearch``` or ```storage.type=cassandra```

```yaml
spark:
  enabled: true
  extraEnv:
    - name: ES_NODES_WAN_ONLY
      value: "true"
```

For a full list of supported environment variables, see the [Spark Dependencies README](https://github.com/jaegertracing/spark-dependencies#readme).

### 5. Query UI

To access the ui you can either:

* enable the ingress and fill at least one host
* provide your own ingress
* or port forward ```kubectl port-forward --namespace {{ .Release.Namespace }} $POD_NAME 16686:16686 --address 0.0.0.0``` and access at http://localhost:16686/

```yaml
jaeger:
  ingress:
    enabled: true
    hosts:
      - <fill a host here>
```

You can customize the UI by setting ```uiconfig```.  Please see the values.yaml for examples or https://github.com/jaegertracing/jaeger/tree/main/cmd/jaeger

## Configuring the Collector

The Jaeger v2 configuration is defined in `config` using OpenTelemetry Collector syntax. You can override pipelines, receivers, and processors there.

```yaml
config:
  service:
    pipelines:
      traces:
        receivers: [otlp, jaeger, zipkin]
        processors: [batch]
        exporters: [jaeger_storage_exporter]
```

## Ports

The unified Service exposes the following ports:

- **Query UI**: 16686, 16685 (gRPC)
- **OTLP**: 4317 (gRPC), 4318 (HTTP)
- **Jaeger**: 14250 (gRPC), 14268 (HTTP), 6831/6832 (UDP)
- **Zipkin**: 9411
