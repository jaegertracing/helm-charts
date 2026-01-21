# Copyright (c) 2019 The Jaeger Authors.
# SPDX-License-Identifier: Apache-2.0

.PHONY: lint
lint:
	ct lint --config ct.yaml

.PHONY: test
test:
	ct install --config ct.yaml

.PHONY: test-jaeger-env-vars
test-jaeger-env-vars:
	ct install --config ct.yaml \
		--charts charts/jaeger \
		--helm-extra-set-args " \
		--set jaeger.extraEnv[0].name=OTEL_TRACES_SAMPLER \
		--set jaeger.extraEnv[0].value=always_off"
