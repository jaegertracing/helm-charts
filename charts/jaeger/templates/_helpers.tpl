{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "jaeger.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "jaeger.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "jaeger.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "jaeger.labels" -}}
helm.sh/chart: {{ include "jaeger.chart" . }}
{{ include "jaeger.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "jaeger.selectorLabels" -}}
app.kubernetes.io/name: {{ include "jaeger.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the cassandra schema service account to use
*/}}
{{- define "jaeger.cassandraSchema.serviceAccountName" -}}
{{- if .Values.schema.serviceAccount.create -}}
    {{ default (printf "%s-cassandra-schema" (include "jaeger.fullname" .)) .Values.schema.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.schema.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the spark service account to use
*/}}
{{- define "jaeger.spark.serviceAccountName" -}}
{{- if .Values.spark.serviceAccount.create -}}
    {{ default (printf "%s-spark" (include "jaeger.fullname" .)) .Values.spark.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.spark.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the hotrod service account to use
*/}}
{{- define "jaeger.hotrod.serviceAccountName" -}}
{{- if .Values.hotrod.serviceAccount.create -}}
    {{ default (printf "%s-hotrod" (include "jaeger.fullname" .)) .Values.hotrod.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.hotrod.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the query service account to use
*/}}
{{- define "jaeger.query.serviceAccountName" -}}
{{- if .Values.query.serviceAccount.create -}}
    {{ default (include "jaeger.query.name" .) .Values.query.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.query.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the agent service account to use
*/}}
{{- define "jaeger.agent.serviceAccountName" -}}
{{- if .Values.agent.serviceAccount.create -}}
    {{ default (include "jaeger.agent.name" .) .Values.agent.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.agent.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the collector service account to use
*/}}
{{- define "jaeger.collector.serviceAccountName" -}}
{{- if .Values.collector.serviceAccount.create -}}
    {{ default (include "jaeger.collector.name" .) .Values.collector.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.collector.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the ingester service account to use
*/}}
{{- define "jaeger.ingester.serviceAccountName" -}}
{{- if .Values.ingester.serviceAccount.create -}}
    {{ default (include "jaeger.ingester.name" .) .Values.ingester.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.ingester.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create a fully qualified query name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "jaeger.query.name" -}}
{{- $nameGlobalOverride := printf "%s-query" (include "jaeger.fullname" .) -}}
{{- if .Values.query.fullnameOverride -}}
{{- printf "%s" .Values.query.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" $nameGlobalOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create a fully qualified agent name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "jaeger.agent.name" -}}
{{- $nameGlobalOverride := printf "%s-agent" (include "jaeger.fullname" .) -}}
{{- if .Values.agent.fullnameOverride -}}
{{- printf "%s" .Values.agent.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" $nameGlobalOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create a fully qualified collector name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "jaeger.collector.name" -}}
{{- $nameGlobalOverride := printf "%s-collector" (include "jaeger.fullname" .) -}}
{{- if .Values.collector.fullnameOverride -}}
{{- printf "%s" .Values.collector.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" $nameGlobalOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create a fully qualified ingester name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "jaeger.ingester.name" -}}
{{- $nameGlobalOverride := printf "%s-ingester" (include "jaeger.fullname" .) -}}
{{- if .Values.ingester.fullnameOverride -}}
{{- printf "%s" .Values.ingester.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" $nameGlobalOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "cassandra.host" -}}
{{- if .Values.provisionDataStore.cassandra -}}
{{- if .Values.storage.cassandra.nameOverride }}
{{- printf "%s" .Values.storage.cassandra.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name "cassandra" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- else }}
{{- .Values.storage.cassandra.host }}
{{- end -}}
{{- end -}}

{{- define "cassandra.contact_points" -}}
{{- $port := .Values.storage.cassandra.port | toString }}
{{- if .Values.provisionDataStore.cassandra -}}
{{- if .Values.storage.cassandra.nameOverride }}
{{- $host := printf "%s" .Values.storage.cassandra.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- printf "%s:%s" $host $port }}
{{- else }}
{{- $host := printf "%s-%s" .Release.Name "cassandra" | trunc 63 | trimSuffix "-" -}}
{{- printf "%s:%s" $host $port }}
{{- end -}}
{{- else }}
{{- printf "%s:%s" .Values.storage.cassandra.host $port }}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "elasticsearch.client.url" -}}
{{- $port := .Values.storage.elasticsearch.port | toString -}}
{{- printf "%s://%s:%s" .Values.storage.elasticsearch.scheme .Values.storage.elasticsearch.host $port }}
{{- end -}}

{{- define "jaeger.hotrod.tracing.host" -}}
{{- default (include "jaeger.agent.name" .) .Values.hotrod.tracing.host -}}
{{- end -}}


{{/*
Configure list of IP CIDRs allowed access to load balancer (if supported)
*/}}
{{- define "loadBalancerSourceRanges" -}}
{{- if .service.loadBalancerSourceRanges }}
  loadBalancerSourceRanges:
  {{- range $cidr := .service.loadBalancerSourceRanges }}
    - {{ $cidr }}
  {{- end }}
{{- end }}
{{- end -}}

{{- define "helm-toolkit.utils.joinListWithComma" -}}
{{- $local := dict "first" true -}}
{{- range $k, $v := . -}}{{- if not $local.first -}},{{- end -}}{{- $v -}}{{- $_ := set $local "first" false -}}{{- end -}}
{{- end -}}
