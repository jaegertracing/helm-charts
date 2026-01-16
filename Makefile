# Copyright (c) 2019 The Jaeger Authors.
# SPDX-License-Identifier: Apache-2.0

.PHONY: lint
lint:
	ct lint --config ct.yaml

.PHONY: test
test:
	ct install --config ct.yaml
