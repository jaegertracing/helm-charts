# Agent Instructions (LLM)

Follow these steps whenever you modify the charts. Keep answers concise and actionable.

## Always do
- Use supported, security-patched chart versions. Verify availability with `helm search repo <name> --versions` before pinning.
- Update dependencies in `charts/jaeger/Chart.yaml`, then run `helm dependency update charts/jaeger` to vendor them.
- Bump `version` in `charts/jaeger/Chart.yaml` for any functional change (deps, templates, values, docs that affect behavior). Only change `appVersion` when updating the Jaeger image.
- Keep Bitnami `common` unless you also replace all `common.*` helpers in templates.
- Run `helm lint charts/jaeger` after changes; add `helm template ...` if you touched templates or defaults.

## Dependency specifics
- Elasticsearch: use `elastic/elasticsearch`; pin the latest safe patch; confirm with search before setting the version.
- Kafka: use `strimzi/strimzi-kafka-operator`; remember this installs the operator only—Kafka clusters require separate CRs.
- Avoid archived repos; replace incubator deps when possible.

## Docs and values
- Update `charts/jaeger/values.yaml` comments/examples to match new defaults or dependencies.
- Update `charts/jaeger/README.md` for any repo/command changes and note required manual steps (e.g., Strimzi Kafka CRs).
- Keep example hosts consistent with rendered service names (use `fullnameOverride` if you change them).

## Before you finish
- Dependencies vendored under `charts/jaeger/charts/*` are current.
- Chart version bumped appropriately.
- Lint passes; templates render for provisioned modes you changed.
- Documentation matches the current behavior and dependency set.
