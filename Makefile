# Copyright (c) 2019 The Jaeger Authors.
# SPDX-License-Identifier: Apache-2.0

.PHONY: lint
lint:
	ct lint --config ct.yaml

.PHONY: test
test:
	ct install --config ct.yaml

# This test will spin up the local provisioned elasticsearch and then connect jaeger to it not using memory store
# it disables the built-in elasticsearch test since it just checks if it's up and jaeger connecting does the same
# elasticsearch test also requires ssl and jaeger is configured to not require that for local connection
.PHONY: test-jaeger-connect-elasticsearch
test-jaeger-connect-elasticsearch:
	ct install --config ct.yaml \
		--charts charts/jaeger \
		--helm-extra-set-args " \
		--set provisionDataStore.elasticsearch=true \
		--set storage.type=elasticsearch \
		--set elasticsearch.tests.enabled=false \
		--set elasticsearch.readinessProbe.initialDelaySeconds=60 \
		--set elasticsearch.readinessProbe.failureThreshold=10 \
		--set elasticsearch.volumeClaimTemplate.resources.requests.storage=5Gi \
		--set elasticsearch.protocol=http \
		--set config.extensions.jaeger_query.storage.traces=primary_store_elasticsearch \
		--set config.extensions.jaeger_query.storage.traces_archive=archive_store_elasticsearch \
		--set config.exporters.jaeger_storage_exporter.trace_storage=primary_store_elasticsearch "