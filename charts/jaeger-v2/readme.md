# Jaeger Helm Chart Deployment (Version 2) Documentation

## Overview

This document outlines the steps to deploy the Jaeger Helm chart (version 2) and provides information on how to use a custom `values.yaml` configuration file during installation. The Jaeger Helm chart includes multiple sub-charts for data stores like Cassandra, Elasticsearch, and Kafka.

## Directory Structure

The structure of the Jaeger Helm chart is as follows:

```bash
kali@PC:~/LFX/helm-charts/charts/jaeger-v2$ tree
.
├── Chart.lock
├── Chart.yaml
├── charts
│   ├── cassandra.tgz
│   ├── common.tgz
│   ├── elasticsearch.tgz
│   └── kafka.tgz
├── readme.md
├── templates
│   ├── _helpers.tpl
│   ├── config-map.yaml
│   └── deployment.yaml
└── values.yaml

3 directories, 11 files
```

### Key Files
- **Chart.yaml**: Contains metadata about the Helm chart such as the chart version, name, and dependencies.
- **templates/**: This directory contains Kubernetes manifests that are templated by Helm and used for the deployment of the Jaeger application. Key templates include:
  - `config-map.yaml`: Configures the ConfigMap for the application.
  - `deployment.yaml`: Contains the template for the Kubernetes deployment of Jaeger.
- **values.yaml**: This file contains default configuration values for the chart, which are applied unless overridden by a custom file.
- **charts/**: Contains Helm chart dependencies such as Cassandra, Elasticsearch, Kafka, and common utilities.
- **readme.md**: Provides chart-specific documentation.

## Helm Installation

You can install the Jaeger Helm chart with the following commands:

### Basic Installation

To install the Jaeger chart using the default values from the included `values.yaml`:

```bash
helm install <chart_name> ./
```

- `<chart_name>` is the name you want to give your release.

### Installation with Custom Values

If you want to use a custom configuration, you can pass a custom `values.yaml` file. This allows you to override the default values specified in the chart’s `values.yaml`.

Use the following command to install the chart with a custom values file:

```bash
helm install <chart_name> ./ -f <custom_values.yaml>
```

- Replace `<chart_name>` with the desired name for your Helm release.
- Replace `<custom_values.yaml>` with the path to your custom configuration file.

### Example:

```bash
helm install jaeger-v2 ./ -f my-config-values.yaml
```

This command installs the Jaeger chart and uses `my-config-values.yaml` for overriding any configuration specified in the default `values.yaml`.

## Custom Values

When deploying Jaeger using a custom values file, any configuration set in the file will take precedence over the default settings in `values.yaml`. For example, you can modify parameters for `receivers`, `processors`, `exporters`, and more within your custom values file.

### Example Custom `values.yaml`

```yaml

    service:
      extensions: [jaeger_storage, jaeger_query, remote_sampling, healthcheckv2]
      pipelines:
        traces:
          receivers: [otlp, jaeger, zipkin]
          processors: [batch, adaptive_sampling]
          exporters: [jaeger_storage_exporter]

    extensions:
      healthcheckv2:
        use_v2: true
        http: {}


      jaeger_query:
        storage:
          traces: some_store
          traces_archive: another_store
        ui:
          config_file: ./cmd/jaeger/config-ui.json

      jaeger_storage:
        backends:
          some_store:
            memory:
              max_traces: 90000
          another_store:
            memory:
              max_traces: 90000

      remote_sampling:
        adaptive:
          sampling_store: some_store
          initial_sampling_probability: 0.2
        http: {}
        grpc: {}

    receivers:
      otlp:
        protocols:
          grpc: {}
          http: {}

      jaeger:
        protocols:
          grpc: {}
          thrift_binary: {}
          thrift_compact: {}
          thrift_http: {}

      zipkin: {}

    processors:
      batch: {}
      adaptive_sampling: {}

    exporters:
      jaeger_storage_exporter:
        trace_storage: some_store
```

## Dependencies

This Helm chart comes with pre-packaged dependencies for data stores:
- **Cassandra**: Version
- **Elasticsearch**: Version
- **Kafka**: Version
- **Common**: Version

These dependencies can be managed through the `charts/` directory, and they are installed as part of the Jaeger deployment.

## Uninstallation

To uninstall the Helm release, use the following command:

```bash
helm uninstall <chart_name>
```

This will remove all Kubernetes resources created by the chart, including ConfigMaps, Deployments, Services, and StatefulSets.

## Conclusion

This document provides a summary of how to install and configure the Jaeger Helm chart (version 2) with both default and custom values. Custom configurations can be applied via a user-defined `values.yaml` file using the `-f` flag during installation.# Jaeger Helm Chart Deployment (Version 2) Documentation

