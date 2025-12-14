# Copyright (c) 2019 The Jaeger Authors.
# SPDX-License-Identifier: Apache-2.0

.PHONY: lint
lint:
	ct lint --config ct.yaml

.PHONY: test
test:
	ct install --config ct.yaml

.PHONY: test-es
test-es:
	ct install --config ct.yaml \
		--charts charts/jaeger \
		--helm-extra-set-args " \
		--set provisionDataStore.elasticsearch=true \
		--set storage.type=elasticsearch \
		--set elasticsearch.master.masterOnly=false \
		--set elasticsearch.master.replicaCount=1 \
		--set elasticsearch.data.replicaCount=0 \
		--set elasticsearch.coordinating.replicaCount=0 \
		--set elasticsearch.ingest.replicaCount=0 \
		--set elasticsearch.clusterHealthCheckParams=wait_for_status=yellow&timeout=1s \
		--set storage.elasticsearch.scheme=https \
		--set storage.elasticsearch.tls.insecure=true"
