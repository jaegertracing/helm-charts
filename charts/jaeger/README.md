# Jaeger

[Jaeger](https://www.jaegertracing.io/) is a distributed tracing system.

## Introduction

This chart deploys Jaeger v2, which uses a unified binary built on the OpenTelemetry Collector framework. The chart supports multiple deployment modes and storage backends including in-memory, Elasticsearch, and Cassandra.

By default, the chart deploys Jaeger in **all-in-one mode** with **in-memory storage**, which is suitable for testing and development. For production deployments, it is recommended to use Elasticsearch as the storage backend.

## Installing the Chart

Add the Jaeger Tracing Helm repository:

```bash
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
```

To install a release named `jaeger`:

```bash
helm install jaeger jaegertracing/jaeger
```

By default, the chart deploys:

- Jaeger All-in-One Deployment (combines collector, query, and internal components)
- In-memory storage (non-persistent)

## Configuration

Jaeger v2 uses a YAML-based configuration format built on the OpenTelemetry Collector framework. The configuration is defined in the `config` section of the values file.

See [Customizing the Chart Before Installing](https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing). To see all configurable options with detailed comments, visit the chart's [values.yaml](https://github.com/jaegertracing/helm-charts/blob/v2/charts/jaeger/values.yaml), or run these configuration commands:

```console
$ helm show values jaegertracing/jaeger
```

You may also `helm show values` on this chart's [dependencies](#dependencies) for additional options.

### User Configuration

You can provide custom configuration by creating a YAML config file and passing it via the `userconfig` parameter:

```bash
helm install jaeger jaegertracing/jaeger \
    --set-file userconfig=path/to/configfile.yaml
```

### Default Configuration Structure

The default configuration uses the OpenTelemetry Collector format with Jaeger-specific extensions:

```yaml
config:
  service:
    extensions: [jaeger_storage, jaeger_query, healthcheckv2]
    pipelines:
      traces:
        receivers: [otlp, jaeger, zipkin]
        processors: [batch]
        exporters: [jaeger_storage_exporter]

  extensions:
    jaeger_query:
      storage:
        traces: primary_store
        traces_archive: archive_store

    jaeger_storage:
      backends:
        primary_store:
          memory:
            max_traces: 100000
        archive_store:
          memory:
            max_traces: 100000

  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: 0.0.0.0:4317
        http:
          endpoint: 0.0.0.0:4318
    jaeger:
      protocols:
        grpc:
    zipkin:

  processors:
    batch:

  exporters:
    jaeger_storage_exporter:
      trace_storage: primary_store
```

### Dependencies

If installing with a dependency such as Elasticsearch and/or Kafka,
their values can be shown by running:

```console
helm repo add bitnami https://charts.bitnami.com/bitnami
helm show values bitnami/elasticsearch
```

```console
helm repo add bitnami https://charts.bitnami.com/bitnami
helm show values bitnami/kafka
```

Please note, any dependency values must be nested within the key named after the
chart, i.e. `elasticsearch`, `cassandra` and/or `kafka`.

## Storage

Jaeger v2 supports multiple storage backends. For production deployments, the Jaeger team [recommends Elasticsearch backend over Cassandra](https://www.jaegertracing.io/docs/latest/faq/#what-is-the-recommended-storage-backend).

The storage backend is configured via the `jaeger_storage` extension in the `config` section.

### Storage Configuration Options

#### Primary Storage Settings

Configure primary storage via `.Values.config.extensions.jaeger_storage.backends.primary_store`:

- `.Values.config.extensions.jaeger_storage.backends.primary_store.elasticsearch.index_prefix`: Set the prefix for Elasticsearch indices
- `.Values.config.extensions.jaeger_storage.backends.primary_store.elasticsearch.server_urls`: Elasticsearch server URLs
- `.Values.config.extensions.jaeger_storage.backends.primary_store.elasticsearch.username`: Username for Elasticsearch authentication
- `.Values.config.extensions.jaeger_storage.backends.primary_store.elasticsearch.password`: Password for Elasticsearch authentication

#### Archive Storage Settings

Configure archive storage via `.Values.config.extensions.jaeger_storage.backends.archive_store`:

- `.Values.config.extensions.jaeger_storage.backends.archive_store.elasticsearch.index_prefix`
- `.Values.config.extensions.jaeger_storage.backends.archive_store.elasticsearch.server_urls`
- `.Values.config.extensions.jaeger_storage.backends.archive_store.elasticsearch.username`
- `.Values.config.extensions.jaeger_storage.backends.archive_store.elasticsearch.password`

### All-in-One Mode (Default)

The default deployment uses all-in-one mode with in-memory storage. This is suitable for testing and development:

```bash
helm install jaeger jaegertracing/jaeger
```

To customize resources and environment variables:

```yaml
allInOne:
  enabled: true
  extraEnv:
    - name: QUERY_BASE_PATH
      value: /jaeger
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 256m
      memory: 128Mi
```

### Elasticsearch Configuration

#### Installing the Chart with Elasticsearch (Provisioned)

To deploy Jaeger with a provisioned Elasticsearch cluster:

**Single Master Node Configuration** (for basic setups):

```bash
helm install jaeger jaegertracing/jaeger \
    --set provisionDataStore.elasticsearch=true \
    --set allInOne.enabled=false \
    --set storage.type=elasticsearch \
    --set elasticsearch.master.masterOnly=false \
    --set elasticsearch.master.replicaCount=1 \
    --set elasticsearch.data.replicaCount=0 \
    --set elasticsearch.coordinating.replicaCount=0 \
    --set elasticsearch.ingest.replicaCount=0 \
    --set collector.enabled=true \
    --set query.enabled=true
```

**Default Configuration** (with default Elasticsearch settings):

```bash
helm install jaeger jaegertracing/jaeger \
    --set provisionDataStore.elasticsearch=true \
    --set allInOne.enabled=false \
    --set storage.type=elasticsearch \
    --set collector.enabled=true \
    --set query.enabled=true
```

#### Elasticsearch Rollover

If using the [Elasticsearch
Rollover](https://www.jaegertracing.io/docs/latest/deployment/#elasticsearch-rollover)
feature, elasticsearch must already be present and so must be deployed
separately from this chart, if not the rollover init hook won't be able to
complete successfully.

#### Installing the Chart using an Existing Elasticsearch Cluster

A release can be configured as follows to use an existing ElasticSearch cluster as the storage backend:

```console
helm install jaeger jaegertracing/jaeger \
  --set allInOne.enabled=false \
  --set storage.type=elasticsearch \
  --set storage.elasticsearch.host=<HOST> \
  --set storage.elasticsearch.port=<PORT> \
  --set storage.elasticsearch.user=<USER> \
  --set storage.elasticsearch.password=<password> \
  --set collector.enabled=true \
  --set query.enabled=true
```

#### Installing the Chart using an Existing ElasticSearch Cluster with TLS

If you already have an existing running ElasticSearch cluster with TLS, you can configure the chart as follows to use it as your backing store:

Content of the `jaeger-values.yaml` file:

```YAML
allInOne:
  enabled: false

storage:
  type: elasticsearch
  elasticsearch:
    host: <HOST>
    port: <PORT>
    scheme: https
    user: <USER>
    password: <PASSWORD>
    tls:
      enabled: true
      secretName: es-tls-secret

collector:
  enabled: true

query:
  enabled: true
```

Generate the TLS secret:

```console
kubectl create secret generic es-tls-secret --from-file=ca-cert.pem=es.pem
```

```console
helm install jaeger jaegertracing/jaeger --values jaeger-values.yaml
```

### Cassandra Configuration

> **Note:** Cassandra support is available for backward compatibility. For new deployments, Elasticsearch is recommended.

#### Installing the Chart using an Existing Cassandra Cluster

If you already have an existing running Cassandra cluster, you can configure the chart as follows to use it as your backing store (make sure you replace `<HOST>`, `<PORT>`, etc with your values):

```console
helm install jaeger jaegertracing/jaeger \
  --set allInOne.enabled=false \
  --set provisionDataStore.cassandra=false \
  --set storage.cassandra.host=<HOST> \
  --set storage.cassandra.port=<PORT> \
  --set storage.cassandra.user=<USER> \
  --set storage.cassandra.password=<PASSWORD> \
  --set collector.enabled=true \
  --set query.enabled=true
```

#### Installing the Chart using an Existing Cassandra Cluster with TLS

If you already have an existing running Cassandra cluster with TLS, you can configure the chart as follows to use it as your backing store:

Content of the `values.yaml` file:

```YAML
allInOne:
  enabled: false

storage:
  type: cassandra
  cassandra:
    host: <HOST>
    port: <PORT>
    user: <USER>
    password: <PASSWORD>
    tls:
      enabled: true
      secretName: cassandra-tls-secret

provisionDataStore:
  cassandra: false

collector:
  enabled: true

query:
  enabled: true
```

Content of the `jaeger-tls-cassandra-secret.yaml` file:

```YAML
apiVersion: v1
kind: Secret
metadata:
  name: cassandra-tls-secret
data:
  commonName: <SERVER NAME>
  ca-cert.pem: |
    -----BEGIN CERTIFICATE-----
    <CERT>
    -----END CERTIFICATE-----
  client-cert.pem: |
    -----BEGIN CERTIFICATE-----
    <CERT>
    -----END CERTIFICATE-----
  client-key.pem: |
    -----BEGIN RSA PRIVATE KEY-----
    -----END RSA PRIVATE KEY-----
  cqlshrc: |
    [ssl]
    certfile = ~/.cassandra/ca-cert.pem
    userkey = ~/.cassandra/client-key.pem
    usercert = ~/.cassandra/client-cert.pem

```

```console
kubectl apply -f jaeger-tls-cassandra-secret.yaml
helm install jaeger jaegertracing/jaeger --values values.yaml
```

### Ingester Configuration (Legacy)

> **Note:** The ingester component is from the Jaeger v1 architecture. In Jaeger v2, the architecture is unified and may not require separate ingester components.

#### Installing the Chart with Ingester enabled

The architecture illustrated below can be achieved by enabling the ingester component. When enabled, Cassandra or Elasticsearch (depending on the configured values) now becomes the ingester's storage backend, whereas Kafka becomes the storage backend of the collector service.

![Jaeger with Ingester](https://www.jaegertracing.io/img/architecture-v2.png)

#### Installing the Chart with Ingester enabled using a New Kafka Cluster

To provision a new Kafka cluster along with jaeger-ingester:

```console
helm install jaeger jaegertracing/jaeger \
  --set allInOne.enabled=false \
  --set provisionDataStore.kafka=true \
  --set ingester.enabled=true \
  --set collector.enabled=true \
  --set query.enabled=true
```

#### Installing the Chart with Ingester using an existing Kafka Cluster

You can use an existing Kafka cluster with jaeger too

```console
helm install jaeger jaegertracing/jaeger \
  --set allInOne.enabled=false \
  --set ingester.enabled=true \
  --set storage.kafka.brokers={<BROKER1:PORT>,<BROKER2:PORT>} \
  --set storage.kafka.topic=<TOPIC> \
  --set collector.enabled=true \
  --set query.enabled=true
```

### Other Storage Configuration (Legacy)

> **Note:** grpc-plugin storage is from Jaeger v1 architecture. Check if your plugin is compatible with Jaeger v2.

If you are using grpc-plugin based storage, you can set environment
variables that are needed by the plugin.

As an example if using the [jaeger-mongodb](https://github.com/mongodb-labs/jaeger-mongodb)
plugin you can set the `MONGO_URL` as follows...

```YAML
storage:
  type: grpc-plugin
  grpcPlugin:
    extraEnv:
      - name: MONGO_URL
        valueFrom:
          secretKeyRef:
            key: MONGO_URL
            name: jaeger-secrets
```

## Separate Collector and Query Mode

For production deployments requiring scalability, you can deploy Jaeger with separate collector and query services instead of all-in-one mode:

```yaml
allInOne:
  enabled: false

collector:
  enabled: true
  replicaCount: 2

query:
  enabled: true
  replicaCount: 2

provisionDataStore:
  elasticsearch: true

storage:
  type: elasticsearch
```

## oAuth2 Sidecar

If extra protection of the Jaeger UI is needed, then the oAuth2 sidecar can be enabled in the Jaeger Query. The oAuth2
sidecar acts as a security proxy in front of the Jaeger Query service and enforces user authentication before reaching
the Jaeger UI. This method can work with any valid provider including Keycloak, Azure, Google, GitHub, and more.

Official docs [here](https://oauth2-proxy.github.io/oauth2-proxy/docs/behaviour)

Content of the `jaeger-values.yaml` file:

```YAML
query:
  enabled: true
  oAuthSidecar:
    enabled: true
    resources: {}
    image:
      registry: quay.io
      repository: oauth2-proxy/oauth2-proxy
      tag: v7.6.0
    pullPolicy: IfNotPresent
    containerPort: 4180
    args:
      - --config
      - /etc/oauth2-proxy/oauth2-proxy.cfg
      - --client-secret
      - "$(client-secret)"
    extraEnv:
      - name: client-secret
        valueFrom:
          secretKeyRef:
            name: client-secret
            key: client-secret-key
    extraConfigmapMounts: []
    extraSecretMounts: []
    config: |-
      provider = "oidc"
      https_address = ":4180"
      upstreams = ["http://localhost:16686"]
      redirect_url = "https://jaeger-svc-domain/oauth2/callback"
      client_id = "jaeger-query"
      oidc_issuer_url = "https://keycloak-svc-domain/auth/realms/Default"
      cookie_secure = "true"
      cookie_secret = ""
      email_domains = "*"
      oidc_groups_claim = "groups"
      user_id_claim = "preferred_username"
      skip_provider_button = "true"
```

## Installing extra kubernetes objects

If additional kubernetes objects need to be installed alongside this chart, set the `extraObjects` array to contain
the yaml describing these objects. The values in the array are treated as a template to allow the use of variable
substitution and function calls as in the example below.

Content of the `jaeger-values.yaml` file:

```YAML
extraObjects:
  - apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: "{{ .Release.Name }}-someRoleBinding"
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: someRole
    subjects:
      - kind: ServiceAccount
        name: "{{ include \"jaeger.esLookback.serviceAccountName\" . }}"
```

## Configuring the hotrod example application to send traces to the OpenTelemetry collector

If the `hotrod` example application is enabled it will export traces to Jaeger
via the Jaeger exporter. To switch this to another collector and/or protocol,
such as an OpenTelemetry OTLP Collector, see the example below.

The primary use case of sending the traces to the collector instead of directly
to Jaeger is to verify traces can get back to Jaeger or another distributed
tracing store and verify that pipeline with the pre-instrumented hotrod
application.

**NOTE: This will not install or setup the OpenTelemetry collector. To setup an example OpenTelemetry Collector, see the [OpenTelemetry helm
charts](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-collector).**

Content of the `jaeger-values.yaml` file:

```YAML
hotrod:
  enabled: true
  # Switch from the jaeger protocol to OTLP
  extraArgs:
    - --otel-exporter=otlp
  # Set the address of the OpenTelemetry collector endpoint
  extraEnv:
    - name: OTEL_EXPORTER_OTLP_ENDPOINT
      value: http://my-otel-collector-opentelemetry-collector:4318
```

## Updating Kafka to Kraft Mode

In the Kafka Helm Chart version 24.0.0 major refactors were done to support Kraft mode. More information can be found [here](https://github.com/bitnami/charts/tree/main/bitnami/kafka#to-2400).

#### Upgrading from Kraft mode

If you are upgrading from Kraft mode, follow the instructions [here](https://github.com/bitnami/charts/tree/main/bitnami/kafka#upgrading-from-zookeeper-mode).

#### Upgrading from Zookeeper mode

If you are upgrading from Zookeeper mode, follow the instructions [here](https://github.com/bitnami/charts/tree/main/bitnami/kafka#upgrading-from-zookeeper-mode).

After you complete the steps above, follow the instructions [here](https://github.com/bitnami/charts/tree/main/bitnami/kafka#migrating-from-zookeeper-early-access) to finally migrate from Zookeeper.
