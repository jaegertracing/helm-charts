#!/bin/bash
set -e
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
    --set elasticsearch.clusterHealthCheckParams=wait_for_status=yellow&timeout=1s"
