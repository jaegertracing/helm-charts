# Jaeger Tracing Helm Repository

![Jaeger](https://www.jaegertracing.io/img/jaeger-logo.png)

## Add the Jaeger Tracing Helm repository

```bash
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
```

## Install Jaeger

```bash
helm upgrade -i jaeger jaegertracing/jaeger
```

For more details on installing Jaeger please see the [chart's README](https://github.com/jaegertracing/helm-charts/tree/master/charts/jaeger).

## Install Jaeger Operator

```bash
helm upgrade -i jaeger-operator jaegertracing/jaeger-operator
```

For more details on installing Jaeger Operator please see the [chart's README](https://github.com/jaegertracing/helm-charts/tree/master/charts/jaeger-operator).
