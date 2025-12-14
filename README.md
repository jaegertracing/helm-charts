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

### Running chart-testing locally

The lint step requires `yamllint` to be available on your `PATH`. If you use a virtual environment (e.g., `.venv`), prepend its `bin` directory when invoking `ct lint`, for example:

```bash
PATH="$(pwd)/.venv/bin:$PATH" ct lint --config ct.yaml
PATH="$(pwd)/.venv/bin:$PATH" ct lint --config ct.yaml
```

To run the full chart installation test locally (simulating the CI environment), you can use the provided helper script. This requires a running local Kubernetes cluster (e.g., Kind) and Docker.

```bash
./run_ct_local.sh
```


## Contributing

We'd love to have you contribute! Please refer to our [contribution guidelines](CONTRIBUTING.md) for details.

## License

[Apache 2.0 License](./LICENSE).
