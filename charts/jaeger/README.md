# Jaeger

[Jaeger](https://www.jaegertracing.io/) is a distributed tracing system.

## Introduction

This chart adds all components required to run Jaeger as described in the [jaeger-kubernetes](https://github.com/jaegertracing/jaeger-kubernetes) GitHub page for a production-like deployment. The chart default will deploy a new Cassandra cluster (using the [cassandra chart](https://github.com/kubernetes/charts/tree/master/incubator/cassandra)), but also supports using an existing Cassandra cluster, deploying a new ElasticSearch cluster (using the [elasticsearch chart](https://github.com/elastic/helm-charts/tree/master/elasticsearch)), or connecting to an existing ElasticSearch cluster. Once the storage backend is available, the chart will deploy jaeger-agent as a DaemonSet and deploy the jaeger-collector and jaeger-query components as Deployments.

## Installing the Chart

Add the Jaeger Tracing Helm repository:

```bash
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
```

To install the chart with the release name `jaeger`, run the following command:

```bash
helm install jaeger jaegertracing/jaeger
```

By default, the chart deploys the following:

- Jaeger Agent DaemonSet
- Jaeger Collector Deployment
- Jaeger Query (UI) Deployment
- Cassandra StatefulSet

![Jaeger with Default components](https://www.jaegertracing.io/img/architecture-v1.png)

IMPORTANT NOTE: For testing purposes, the footprint for Cassandra can be reduced significantly in the event resources become constrained (such as running on your local laptop or in a Vagrant environment). You can override the resources required run running this command:

```bash
helm install jaeger jaegertracing/jaeger \
  --set cassandra.config.max_heap_size=1024M \
  --set cassandra.config.heap_new_size=256M \
  --set cassandra.resources.requests.memory=2048Mi \
  --set cassandra.resources.requests.cpu=0.4 \
  --set cassandra.resources.limits.memory=2048Mi \
  --set cassandra.resources.limits.cpu=0.4
```

## Installing the Chart using an Existing Cassandra Cluster

If you already have an existing running Cassandra cluster, you can configure the chart as follows to use it as your backing store (make sure you replace `<HOST>`, `<PORT>`, etc with your values):

```bash
helm install jaeger jaegertracing/jaeger \
  --set provisionDataStore.cassandra=false \
  --set storage.cassandra.host=<HOST> \
  --set storage.cassandra.port=<PORT> \
  --set storage.cassandra.user=<USER> \
  --set storage.cassandra.password=<PASSWORD>
```

## Installing the Chart using an Existing Cassandra Cluster with TLS

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

```bash
kubectl apply -f jaeger-tls-cassandra-secret.yaml
helm install jaeger jaegertracing/jaeger --values values.yaml
```

## Installing the Chart using a New ElasticSearch Cluster

To install the chart with the release name `jaeger` using a new ElasticSearch cluster instead of Cassandra (default), run the following command:

```bash
helm install jaeger jaegertracing/jaeger \
  --set provisionDataStore.cassandra=false \
  --set provisionDataStore.elasticsearch=true \
  --set storage.type=elasticsearch
```

## Installing the Chart using an Existing Elasticsearch Cluster

A release can be configured as follows to use an existing ElasticSearch cluster as it as the storage backend:

```bash
helm install jaeger jaegertracing/jaeger \
  --set provisionDataStore.cassandra=false \
  --set storage.type=elasticsearch \
  --set storage.elasticsearch.host=<HOST> \
  --set storage.elasticsearch.port=<PORT> \
  --set storage.elasticsearch.user=<USER> \
  --set storage.elasticsearch.password=<password>
```

## Installing the Chart using an Existing ElasticSearch Cluster with TLS

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

```bash
keytool -import -trustcacerts -keystore trust.store -storepass changeit -alias es-root -file es.pem
kubectl create configmap jaeger-tls --from-file=trust.store --from-file=es.pem
```

```bash
helm install jaeger jaegertracing/jaeger --values jaeger-values.yaml
```

## Installing the Chart with Ingester enabled

The architecture illustrated below can be achieved by enabling the ingester component. When enabled, Cassandra or Elasticsearch (depending on the configured values) now becomes the ingester's storage backend, whereas Kafka becomes the storage backend of the collector service.

![Jaeger with Ingester](https://www.jaegertracing.io/img/architecture-v2.png)

## Installing the Chart with Ingester enabled using a New Kafka Cluster

To provision a new Kafka cluster along with jaeger-ingester:

```bash
helm install jaeger jaegertracing/jaeger \
  --set provisionDataStore.kafka=true \
  --set ingester.enabled=true
```

## Installing the Chart with Ingester using an existing Kafka Cluster

You can use an exisiting Kafka cluster with jaeger too

```bash
helm install jaeger jaegertracing/jaeger \
  --set ingester.enabled=true \
  --set storage.kafka.brokers={<BROKER1:PORT>,<BROKER2:PORT>} \
  --set storage.kafka.topic=<TOPIC>
```

## Configuration

The following table lists the configurable parameters of the Jaeger chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `<agent\|collector\|query\|ingester>.cmdlineParams` | Additional command line parameters | `nil` |
| `<component>.extraEnv` | Additional environment variables | [] |
| `<component>.nodeSelector` | Node selector | {} |
| `<component>.tolerations` | Node tolerations | [] |
| `<component>.affinity` | Affinity | {} |
| `<component>.podAnnotations` | Pod annotations | `nil` |
| `<component>.podSecurityContext` | Pod security context | {} |
| `<component>.securityContext` | Container security context | {} |
| `<component>.serviceAccount.create` | Create service account | `true` |
| `<component>.serviceAccount.name` | The name of the ServiceAccount to use. If not set and create is true, a name is generated using the fullname template | `nil` |
| `<component>.serviceMonitor.enabled` | Create serviceMonitor | `false` |
| `<component>.serviceMonitor.additionalLabels` | Add additional labels to serviceMonitor | {} |
| `agent.annotations` | Annotations for Agent | `nil` |
| `agent.dnsPolicy` | Configure DNS policy for agents | `ClusterFirst` |
| `agent.service.annotations` | Annotations for Agent SVC | `nil` |
| `agent.service.binaryPort` | jaeger.thrift over binary thrift | `6832` |
| `agent.service.compactPort` | jaeger.thrift over compact thrift| `6831` |
| `agent.image` | Image for Jaeger Agent | `jaegertracing/jaeger-agent` |
| `agent.imagePullSecrets` | Secret to pull the Image for Jaeger Agent | `[]` |
| `agent.pullPolicy` | Agent image pullPolicy | `IfNotPresent` |
| `agent.service.loadBalancerSourceRanges` | list of IP CIDRs allowed access to load balancer (if supported) | `[]` |
| `agent.service.annotations` | Annotations for Agent SVC | `nil` |
| `agent.service.binaryPort` | jaeger.thrift over binary thrift | `6832` |
| `agent.service.compactPort` | jaeger.thrift over compact thrift | `6831` |
| `agent.service.zipkinThriftPort` | zipkin.thrift over compact thrift | `5775` |
| `agent.extraConfigmapMounts` | Additional agent configMap mounts | `[]` |
| `agent.extraSecretMounts` | Additional agent secret mounts | `[]` |
| `agent.useHostNetwork` | Enable hostNetwork for agents | `false` |
| `agent.priorityClassName` | Priority class name for the agent pods | `nil` |
| `collector.autoscaling.enabled` | Enable horizontal pod autoscaling | `false` |
| `collector.autoscaling.minReplicas` | Minimum replicas |  2 |
| `collector.autoscaling.maxReplicas` | Maximum replicas |  10 |
| `collector.autoscaling.targetCPUUtilizationPercentage` | Target CPU utilization |  80 |
| `collector.autoscaling.targetMemoryUtilizationPercentage` | Target memory utilization | `nil` |
| `collector.image` | Image for jaeger collector | `jaegertracing/jaeger-collector` |
| `collector.imagePullSecrets` | Secret to pull the Image for Jaeger Collector | `[]` |
| `collector.pullPolicy` | Collector image pullPolicy | `IfNotPresent` |
| `collector.service.annotations` | Annotations for Collector SVC | `nil` |
| `collector.service.grpc.port` | Jaeger Agent port for model.proto | `14250` |
| `collector.service.http.port` | Client port for HTTP thrift | `14268` |
| `collector.service.loadBalancerSourceRanges` | list of IP CIDRs allowed access to load balancer (if supported) | `[]` |
| `collector.service.type` | Service type | `ClusterIP` |
| `collector.service.zipkin.port` | Zipkin port for JSON/thrift HTTP | `nil` |
| `collector.extraConfigmapMounts` | Additional collector configMap mounts | `[]` |
| `collector.extraSecretMounts` | Additional collector secret mounts | `[]` |
| `collector.samplingConfig` | [Sampling strategies json file](https://www.jaegertracing.io/docs/latest/sampling/#collector-sampling-configuration) | `nil` |
| `collector.priorityClassName` | Priority class name for the collector pods | `nil` |
| `ingester.enabled` | Enable ingester component, collectors will write to Kafka | `false` |
| `ingester.autoscaling.enabled` | Enable horizontal pod autoscaling | `false` |
| `ingester.autoscaling.minReplicas` | Minimum replicas |  2 |
| `ingester.autoscaling.maxReplicas` | Maximum replicas |  10 |
| `ingester.autoscaling.targetCPUUtilizationPercentage` | Target CPU utilization |  80 |
| `ingester.autoscaling.targetMemoryUtilizationPercentage` | Target memory utilization | `nil` |
| `ingester.service.annotations` | Annotations for Ingester SVC | `nil` |
| `ingester.image` | Image for jaeger Ingester | `jaegertracing/jaeger-ingester` |
| `ingester.imagePullSecrets` | Secret to pull the Image for Jaeger Ingester | `[]` |
| `ingester.pullPolicy` | Ingester image pullPolicy | `IfNotPresent` |
| `ingester.service.annotations` | Annotations for Ingester SVC | `nil` |
| `ingester.service.loadBalancerSourceRanges` | list of IP CIDRs allowed access to load balancer (if supported) | `[]` |
| `ingester.service.type` | Service type | `ClusterIP` |
| `ingester.extraConfigmapMounts` | Additional Ingester configMap mounts | `[]` |
| `ingester.extraSecretMounts` | Additional Ingester secret mounts | `[]` |
| `fullnameOverride` | Override full name | `nil` |
| `hotrod.enabled` | Enables the Hotrod demo app | `false` |
| `hotrod.service.loadBalancerSourceRanges` | list of IP CIDRs allowed access to load balancer (if supported) | `[]` |
| `hotrod.image.pullSecrets` | Secret to pull the Image for the Hotrod demo app | `[]` |
| `nameOverride` | Override name| `nil` |
| `provisionDataStore.cassandra` | Provision Cassandra Data Store| `true` |
| `provisionDataStore.elasticsearch` | Provision Elasticsearch Data Store | `false` |
| `provisionDataStore.kafka` | Provision Kafka Data Store | `false` |
| `query.agentSidecar.enabled` | Enable agent sidecare for query deployment | `true` |
| `query.config` | [UI Config json file](https://www.jaegertracing.io/docs/latest/frontend-ui/) | `nil` |
| `query.service.annotations` | Annotations for Query SVC | `nil` |
| `query.image` | Image for Jaeger Query UI | `jaegertracing/jaeger-query` |
| `query.imagePullSecrets` | Secret to pull the Image for Jaeger Query UI | `[]` |
| `query.ingress.enabled` | Allow external traffic access | `false` |
| `query.ingress.annotations` | Configure annotations for Ingress | `{}` |
| `query.ingress.hosts` | Configure host for Ingress | `nil` |
| `query.ingress.tls` | Configure tls for Ingress | `nil` |
| `query.pullPolicy` | Query UI image pullPolicy | `IfNotPresent` |
| `query.service.loadBalancerSourceRanges` | list of IP CIDRs allowed access to load balancer (if supported) | `[]` |
| `query.service.nodePort` | Specific node port to use when type is NodePort | `nil` |
| `query.service.port` | External accessible port | `80` |
| `query.service.type` | Service type | `ClusterIP` |
| `query.basePath` | Base path of Query UI, used for ingress as well (if it is enabled) | `/` |
| `query.extraConfigmapMounts` | Additional query configMap mounts | `[]` |
| `query.priorityClassName` | Priority class name for the Query UI pods | `nil` |
| `schema.annotations` | Annotations for the schema job| `nil` |
| `schema.extraConfigmapMounts` | Additional cassandra schema job configMap mounts | `[]`  |
| `schema.image` | Image to setup cassandra schema | `jaegertracing/jaeger-cassandra-schema` |
| `schema.imagePullSecrets` | Secret to pull the Image for the Cassandra schema setup job | `[]` |
| `schema.pullPolicy` | Schema image pullPolicy | `IfNotPresent` |
| `schema.activeDeadlineSeconds` | Deadline in seconds for cassandra schema creation job to complete | `120` |
| `schema.keyspace` | Set explicit keyspace name | `nil` |
| `spark.enabled` | Enables the dependencies job| `false` |
| `spark.image` | Image for the dependencies job| `jaegertracing/spark-dependencies` |
| `spark.imagePullSecrets` | Secret to pull the Image for the Spark dependencies job | `[]` |
| `spark.pullPolicy` | Image pull policy of the deps image | `Always` |
| `spark.schedule` | Schedule of the cron job | `"49 23 * * *"` |
| `spark.successfulJobsHistoryLimit` | Cron job successfulJobsHistoryLimit | `5` |
| `spark.failedJobsHistoryLimit` | Cron job failedJobsHistoryLimit | `5` |
| `spark.tag` | Tag of the dependencies job image | `latest` |
| `spark.extraConfigmapMounts` | Additional spark configMap mounts | `[]` |
| `spark.extraSecretMounts` | Additional spark secret mounts | `[]` |
| `esIndexCleaner.enabled` | Enables the ElasticSearch indices cleanup job| `false` |
| `esIndexCleaner.image` | Image for the ElasticSearch indices cleanup job| `jaegertracing/jaeger-es-index-cleaner` |
| `esIndexCleaner.imagePullSecrets` | Secret to pull the Image for the ElasticSearch indices cleanup job | `[]` |
| `esIndexCleaner.pullPolicy` | Image pull policy of the ES cleanup image | `Always` |
| `esIndexCleaner.numberOfDays` | ElasticSearch indices older than this number (Number of days) would be deleted by the CronJob | `7`
| `esIndexCleaner.schedule` | Schedule of the cron job | `"55 23 * * *"` |
| `esIndexCleaner.successfulJobsHistoryLimit` | successfulJobsHistoryLimit for ElasticSearch indices cleanup CronJob | `5` |
| `esIndexCleaner.failedJobsHistoryLimit` | failedJobsHistoryLimit for ElasticSearch indices cleanup CronJob | `5` |
| `esIndexCleaner.tag` | Tag of the dependencies job image | `latest` |
| `esIndexCleaner.extraConfigmapMounts` | Additional esIndexCleaner configMap mounts | `[]` |
| `esIndexCleaner.extraSecretMounts` | Additional esIndexCleaner secret mounts | `[]` |
| `esRollover.enabled` | Enables the ElasticSearch rollover job | `false` |
| `esRollover.image` | Image for the ElasticSearch rollover job | `jaegertracing/jaeger-es-rollover` |
| `esRollover.imagePullSecrets` | Secret to pull the Image for the ElasticSearch rollover job | `[]` |
| `esRollover.pullPolicy` | Image pull policy of the ES rollover image | `Always` |
| `esRollover.schedule` | Schedule of the cron job | `"10 0 * * *"` |
| `esRollover.successfulJobsHistoryLimit` | successfulJobsHistoryLimit for ElasticSearch rollover CronJob | `3` |
| `esRollover.failedJobsHistoryLimit` | failedJobsHistoryLimit for ElasticSearch rollover CronJob | `3` |
| `esRollover.tag` | Tag of the rollover job image | `latest` |
| `esRollover.extraConfigmapMounts` | Additional esRollover configMap mounts | `[]` |
| `esRollover.extraSecretMounts` | Additional esRollover secret mounts | `[]` |
| `esRollover.initHook.ttlSecondsAfterFinished` | ttlSecondsAfterFinished for ElasticSearch rollover init hook | `120` |
| `esLookback.enabled` | Enables the ElasticSearch rollover lookback job | `false` |
| `esLookback.image` | Image for the ElasticSearch rollover lookback job | `jaegertracing/jaeger-es-rollover` |
| `esLookback.imagePullSecrets` | Secret to pull the Image for the ElasticSearch rollover lookback job | `[]` |
| `esLookback.pullPolicy` | Image pull policy of the ES rollover image | `Always` |
| `esLookback.schedule` | Schedule of the cron job | `"5 0 * * *"` |
| `esLookback.successfulJobsHistoryLimit` | successfulJobsHistoryLimit for ElasticSearch rollover lookback CronJob | `3` |
| `esLookback.failedJobsHistoryLimit` | failedJobsHistoryLimit for ElasticSearch rollover lookback CronJob | `3` |
| `esLookback.tag` | Tag of the rollover lookback job image | `latest` |
| `esLookback.extraConfigmapMounts` | Additional esLookback configMap mounts | `[]` |
| `esLookback.extraSecretMounts` | Additional esLookback secret mounts | `[]` |
| `storage.cassandra.env` | Extra cassandra related env vars to be configured on components that talk to cassandra | `cassandra` |
| `storage.cassandra.cmdlineParams` | Extra cassandra related command line options to be configured on components that talk to cassandra | `cassandra` |
| `storage.cassandra.existingSecret` | Name of existing password secret object (for password authentication | `nil`
| `storage.cassandra.host` | Provisioned cassandra host | `cassandra` |
| `storage.cassandra.keyspace` | Schema name for cassandra | `jaeger_v1_test` |
| `storage.cassandra.password` | Provisioned cassandra password  (ignored if storage.cassandra.existingSecret set) | `password` |
| `storage.cassandra.port` | Provisioned cassandra port | `9042` |
| `storage.cassandra.tls.enabled` | Provisioned cassandra TLS connection enabled | `false` |
| `storage.cassandra.tls.secretName` | Provisioned cassandra TLS connection existing secret name (possible keys in secret: `ca-cert.pem`, `client-key.pem`, `client-cert.pem`, `cqlshrc`, `commonName`) | `` |
| `storage.cassandra.usePassword` | Use password | `true` |
| `storage.cassandra.user` | Provisioned cassandra username | `user` |
| `storage.elasticsearch.env` | Extra ES related env vars to be configured on components that talk to ES | `nil` |
| `storage.elasticsearch.cmdlineParams` | Extra ES related command line options to be configured on components that talk to ES | `nil` |
| `storage.elasticsearch.existingSecret` | Name of existing password secret object (for password authentication | `nil` |
| `storage.elasticsearch.existingSecretKey` | Key of the declared password secret | `password` |
| `storage.elasticsearch.host` | Provisioned elasticsearch host| `elasticsearch` |
| `storage.elasticsearch.password` | Provisioned elasticsearch password  (ignored if storage.elasticsearch.existingSecret set | `changeme` |
| `storage.elasticsearch.port` | Provisioned elasticsearch port| `9200` |
| `storage.elasticsearch.scheme` | Provisioned elasticsearch scheme | `http` |
| `storage.elasticsearch.usePassword` | Use password | `true` |
| `storage.elasticsearch.user` | Provisioned elasticsearch user| `elastic` |
| `storage.elasticsearch.indexPrefix` | Index Prefix for elasticsearch | `nil` |
| `storage.elasticsearch.nodesWanOnly` | Only access specified es host | `false` |
| `storage.kafka.authentication` | Authentication type used to authenticate with kafka cluster. e.g. none, kerberos, tls | `none` |
| `storage.kafka.brokers` | Broker List for Kafka with port | `kafka:9092` |
| `storage.kafka.topic` | Topic name for Kafka | `jaeger_v1_test` |
| `storage.type` | Storage type (ES or Cassandra)| `cassandra` |
| `tag` | Image tag/version | `1.20.0` |

For more information about some of the tunable parameters that Cassandra provides, please visit the helm chart for [cassandra](https://github.com/kubernetes/charts/tree/master/incubator/cassandra) and the official [website](http://cassandra.apache.org/) at apache.org.

For more information about some of the tunable parameters that Jaeger provides, please visit the official [Jaeger repo](https://github.com/uber/jaeger) at GitHub.com.

### Pending enhancements

- [ ] Sidecar deployment support
