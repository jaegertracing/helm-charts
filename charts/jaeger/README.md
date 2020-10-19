# Jaeger

[Jaeger](https://www.jaegertracing.io/) is a distributed tracing system.

## Introduction

This chart adds all components required to run Jaeger as described in the [jaeger-kubernetes](https://github.com/jaegertracing/jaeger-kubernetes) GitHub page for a production-like deployment. The chart default will deploy a new Cassandra cluster (using the [cassandra chart](https://github.com/kubernetes/charts/tree/master/incubator/cassandra)), but also supports using an existing Cassandra cluster, deploying a new ElasticSearch cluster (using the [elasticsearch chart](https://github.com/elastic/helm-charts/tree/master/elasticsearch)), or connecting to an existing ElasticSearch cluster. Once the storage backend is available, the chart will deploy jaeger-agent as a DaemonSet and deploy the jaeger-collector and jaeger-query components as Deployments.

## Installing the Chart

Add the Jaeger Tracing Helm repository:

```bash
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
```

To install a release named `jaeger`:

```bash
helm install jaeger jaegertracing/jaeger
```

By default, the chart deploys the following:

- Jaeger Agent DaemonSet
- Jaeger Collector Deployment
- Jaeger Query (UI) Deployment
- Cassandra StatefulSet (subject to change!)

![Jaeger with Default
components](https://www.jaegertracing.io/img/architecture-v1.png)

## Configuration

See [Customizing the Chart Before Installing](https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing). To see all configurable options with detailed comments, visit the chart's [values.yaml](https://github.com/jaegertracing/helm-charts/blob/master/charts/jaeger/values.yaml), or run these configuration commands:

```console
# Helm 2
$ helm inspect values jaegertracing/jaeger

# Helm 3
$ helm show values jaegertracing/jaeger
```

You may also `helm show values` on this chart's [dependencies](#dependencies) for additional options.

### Dependencies

If installing with a dependency such as Cassandra, Elasticsearch and/or Kafka
their, values can be shown by running:

```console
helm repo add elastic https://helm.elastic.co

# Helm 2
helm inspect values elastic/elasticsearch

# Helm 3
helm show values elastic/elasticsearch
```

```console
helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/

# Helm 2
helm inspect values incubator/cassandra

# Helm 3
helm show values incubator/cassandra
```

```console
helm repo add bitnami

# Helm 2
helm inspect values bitnami/kafka

# Helm 3
helm show values bitnami/kafka
```

Please note, any dependency values must be nested within the key named after the
chart, i.e. `elasticsearch`, `cassandra` and/or `kafka`.

## Storage

As per Jaeger documentation, for large scale production deployment the Jaeger
team [recommends Elasticsearch backend over Cassandra](https://www.jaegertracing.io/docs/latest/faq/#what-is-the-recommended-storage-backend),
as such the default backend may change in the future and **it is highly
recommended to explicitly configure storage**.

### Elasticsearch configuration

#### Elasticsearch Rollover

If using the [Elasticsearch
Rollover](https://www.jaegertracing.io/docs/latest/deployment/#elasticsearch-rollover)
feature, elasticsearch must already be present and so must be deployed
separately from this chart, if not the rollover init hook won't be able to
complete successfully.

#### Installing the Chart using a New ElasticSearch Cluster

To install the chart with the release name `jaeger` using a new ElasticSearch cluster instead of Cassandra (default), run the following command:

```console
helm install jaeger jaegertracing/jaeger \
  --set provisionDataStore.cassandra=false \
  --set provisionDataStore.elasticsearch=true \
  --set storage.type=elasticsearch
```

#### Installing the Chart using an Existing Elasticsearch Cluster

A release can be configured as follows to use an existing ElasticSearch cluster as it as the storage backend:

```console
helm install jaeger jaegertracing/jaeger \
  --set provisionDataStore.cassandra=false \
  --set storage.type=elasticsearch \
  --set storage.elasticsearch.host=<HOST> \
  --set storage.elasticsearch.port=<PORT> \
  --set storage.elasticsearch.user=<USER> \
  --set storage.elasticsearch.password=<password>
```

#### Installing the Chart using an Existing ElasticSearch Cluster with TLS

If you already have an existing running ElasticSearch cluster with TLS, you can configure the chart as follows to use it as your backing store:

Content of the `jaeger-values.yaml` file:

```YAML
storage:
  type: elasticsearch
  elasticsearch:
    host: <HOST>
    port: <PORT>
    scheme: https
    user: <USER>
    password: <PASSWORD>
provisionDataStore:
  cassandra: false
  elasticsearch: false
query:
  cmdlineParams:
    es.tls.ca: "/tls/es.pem"
  extraConfigmapMounts:
    - name: jaeger-tls
      mountPath: /tls
      subPath: ""
      configMap: jaeger-tls
      readOnly: true
collector:
  cmdlineParams:
    es.tls.ca: "/tls/es.pem"
  extraConfigmapMounts:
    - name: jaeger-tls
      mountPath: /tls
      subPath: ""
      configMap: jaeger-tls
      readOnly: true
spark:
  enabled: true
  cmdlineParams:
    java.opts: "-Djavax.net.ssl.trustStore=/tls/trust.store -Djavax.net.ssl.trustStorePassword=changeit"
  extraConfigmapMounts:
    - name: jaeger-tls
      mountPath: /tls
      subPath: ""
      configMap: jaeger-tls
      readOnly: true

```

Generate configmap jaeger-tls:

```console
keytool -import -trustcacerts -keystore trust.store -storepass changeit -alias es-root -file es.pem
kubectl create configmap jaeger-tls --from-file=trust.store --from-file=es.pem
```

```console
helm install jaeger jaegertracing/jaeger --values jaeger-values.yaml
```

### Cassandra configuration

#### Installing the Chart using an Existing Cassandra Cluster

If you already have an existing running Cassandra cluster, you can configure the chart as follows to use it as your backing store (make sure you replace `<HOST>`, `<PORT>`, etc with your values):

```console
helm install jaeger jaegertracing/jaeger \
  --set provisionDataStore.cassandra=false \
  --set storage.cassandra.host=<HOST> \
  --set storage.cassandra.port=<PORT> \
  --set storage.cassandra.user=<USER> \
  --set storage.cassandra.password=<PASSWORD>
```

#### Installing the Chart using an Existing Cassandra Cluster with TLS

If you already have an existing running Cassandra cluster with TLS, you can configure the chart as follows to use it as your backing store:

Content of the `values.yaml` file:

```YAML
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

### Ingester Configuration

#### Installing the Chart with Ingester enabled

The architecture illustrated below can be achieved by enabling the ingester component. When enabled, Cassandra or Elasticsearch (depending on the configured values) now becomes the ingester's storage backend, whereas Kafka becomes the storage backend of the collector service.

![Jaeger with Ingester](https://www.jaegertracing.io/img/architecture-v2.png)

#### Installing the Chart with Ingester enabled using a New Kafka Cluster

To provision a new Kafka cluster along with jaeger-ingester:

```console
helm install jaeger jaegertracing/jaeger \
  --set provisionDataStore.kafka=true \
  --set ingester.enabled=true
```

#### Installing the Chart with Ingester using an existing Kafka Cluster

You can use an exisiting Kafka cluster with jaeger too

```console
helm install jaeger jaegertracing/jaeger \
  --set ingester.enabled=true \
  --set storage.kafka.brokers={<BROKER1:PORT>,<BROKER2:PORT>} \
  --set storage.kafka.topic=<TOPIC>
```
