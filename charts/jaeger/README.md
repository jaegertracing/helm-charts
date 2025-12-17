# Jaeger Helm Chart

[Jaeger](https://www.jaegertracing.io/) is a distributed tracing system. This chart deploys Jaeger v2 using a unified "All-In-One" architecture built on the OpenTelemetry Collector framework.

## ⚠️ Breaking Changes in v5.0.0

This release (v5.0.0) is a major refactor designed to simplify operation and configuration.

- **Unified Architecture**: All functionality (Collector, Query, Ingester) is now provided by a single "All-in-One" deployment. Legacy split deployments are removed.
- **Configuration Simplification**:
    - **Elasticsearch**: The bespoke `storage.elasticsearch.*` configuration DSL has been **removed**. You must now configure connection details using standard environment variables (e.g., `ES_SERVER_URLS` via `allInOne.extraEnv`).
    - **Spark**: Configuration for Spark dependencies job now requires manual environment variable setup via `spark.extraEnv`. The automatic connection logic has been removed.
- **Component Removal**: The **HotROD** example application has been removed from the chart.
- **Service Consolidation**: A single Service now exposes all ports (agent, collector, query).

## Architecture

This chart uses the **All-In-One** deployment model.
- **Single Binary**: Runs as a `Deployment` scalable to multiple replicas.
- **Stateless**: Can connect to external persistent storage (Elasticsearch, Cassandra) for production use.
- **Default**: Memory storage (ephemeral), suitable for testing.

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

### 1. In-Memory (Default)
Ideal for testing. No persistence.
```bash
helm install jaeger jaegertracing/jaeger
```

### 2. Elasticsearch (Production Recommended)
Configure Jaeger to connect to an existing Elasticsearch cluster using `extraEnv`.

**values.yaml Example:**
```yaml
allInOne:
  extraEnv:
    - name: SPAN_STORAGE_TYPE
      value: elasticsearch
    - name: ES_SERVER_URLS
      value: http://elasticsearch:9200
    - name: ES_USERNAME
      value: elastic
    - name: ES_PASSWORD
      value: changeme
```

**Running Maintenance Jobs:**
To run Index Cleaner or Rollover jobs, enable them and provide connection details:
```yaml
esIndexCleaner:
  enabled: true
  extraEnv:
    - name: ES_SERVER_URLS
      value: http://elasticsearch:9200
```

### 3. Cassandra
To use Cassandra storage:
```yaml
storage:
  type: cassandra
  cassandra:
    host: cassandra-host
    port: 9042
    keyspace: jaeger_v1_test
```
*Note: The chart includes a Schema Job that runs automatically if `storage.type` is `cassandra`.*

### 4. Spark Dependencies
To run the Spark dependencies job (for dependency links graph):
```yaml
spark:
  enabled: true
  extraEnv:
    - name: ES_NODES
      value: http://elasticsearch:9200
    - name: ES_NODES_WAN_ONLY
      value: "true"
```

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
