# Jaeger Helm Charts

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![](https://github.com/jaegertracing/helm-charts/workflows/Release%20Charts/badge.svg?branch=main)](https://github.com/jaegertracing/helm-charts/actions)

This functionality is in beta and is subject to change. The code is provided as-is with no warranties. Beta features are not subject to the support SLA of official GA features.

## Usage

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

Once Helm is set up properly, add the repo as follows:

```console
$ helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
```

You can then run `helm search repo jaegertracing` to see the charts.

See additional documentation:
  * [Jaeger chart](./charts/jaeger)
  * [Jaeger Operator chart](./charts/jaeger-operator)

## Contributing

We'd love to have you contribute! Please refer to our [contribution guidelines](CONTRIBUTING.md) for details.

## License

[Apache 2.0 License](./LICENSE).
