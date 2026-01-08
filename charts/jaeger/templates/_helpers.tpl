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
Create the name of the esIndexCleaner service account to use
*/}}
{{- define "jaeger.esIndexCleaner.serviceAccountName" -}}
{{- if .Values.esIndexCleaner.serviceAccount.create -}}
  {{ default (printf "%s-es-index-cleaner" (include "jaeger.fullname" .)) .Values.esIndexCleaner.serviceAccount.name }}
{{- else -}}
  {{ default "default" .Values.esIndexCleaner.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the esRollover service account to use
*/}}
{{- define "jaeger.esRollover.serviceAccountName" -}}
{{- if .Values.esRollover.serviceAccount.create -}}
  {{ default (printf "%s-es-rollover" (include "jaeger.fullname" .)) .Values.esRollover.serviceAccount.name }}
{{- else -}}
  {{ default "default" .Values.esRollover.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the esLookback service account to use
*/}}
{{- define "jaeger.esLookback.serviceAccountName" -}}
{{- if .Values.esLookback.serviceAccount.create -}}
  {{ default (printf "%s-es-lookback" (include "jaeger.fullname" .)) .Values.esLookback.serviceAccount.name }}
{{- else -}}
  {{ default "default" .Values.esLookback.serviceAccount.name }}
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


{{/*
Cassandra related environment variables
*/}}
{{- define "cassandra.env" -}}
- name: CASSANDRA_SERVERS
  value: {{ include "cassandra.host" . }}
- name: CASSANDRA_PORT
  value: {{ .Values.storage.cassandra.port | quote }}
{{ if .Values.storage.cassandra.tls.enabled }}
- name: CASSANDRA_TLS_ENABLED
  value: "true"
- name: CASSANDRA_TLS_SERVER_NAME
  valueFrom:
    secretKeyRef:
      name: {{ .Values.storage.cassandra.tls.secretName }}
      key: commonName
- name: CASSANDRA_TLS_KEY
  value: "/cassandra-tls/client-key.pem"
- name: CASSANDRA_TLS_CERT
  value: "/cassandra-tls/client-cert.pem"
- name: CASSANDRA_TLS_CA
  value: "/cassandra-tls/ca-cert.pem"
{{- end }}
{{- if .Values.storage.cassandra.keyspace }}
- name: CASSANDRA_KEYSPACE
  value: {{ .Values.storage.cassandra.keyspace }}
{{- end }}
- name: CASSANDRA_USERNAME
  value: {{ .Values.storage.cassandra.user }}
- name: CASSANDRA_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ if .Values.storage.cassandra.existingSecret }}{{ .Values.storage.cassandra.existingSecret }}{{- else }}{{ include "jaeger.fullname" . }}-cassandra{{- end }}
      key: password
{{ range $key, $value := .Values.storage.cassandra.env }}
- name: {{ $key | quote }}
  value: {{ $value | quote }}
{{ end -}}
{{- if .Values.storage.cassandra.extraEnv }}
{{ toYaml .Values.storage.cassandra.extraEnv }}
{{- end }}
{{- end -}}


{{/*
grpcPlugin related environment variables
*/}}
{{- define "grpcPlugin.env" -}}
{{- if .Values.storage.grpcPlugin.extraEnv }}
{{- toYaml .Values.storage.grpcPlugin.extraEnv }}
{{- end }}
{{- end -}}

{{/*
badger related environment variables
*/}}
{{- define "badger.env" -}}
- name: BADGER_EPHEMERAL
  value: {{ .Values.storage.badger.ephemeral | quote }}
{{- if not .Values.storage.badger.ephemeral }}
- name: BADGER_DIRECTORY_VALUE
  value: {{ print .Values.storage.badger.persistence.mountPath "/badger/data" | quote }}
- name: BADGER_DIRECTORY_KEY
  value: {{ print .Values.storage.badger.persistence.mountPath "/badger/key" | quote }}
{{- end }}
{{- if .Values.storage.badger.extraEnv }}
{{- toYaml .Values.storage.badger.extraEnv }}
{{- end }}
{{- end -}}

{{/*
memory related environment variables
*/}}
{{- define "memory.env" -}}
{{- if .Values.storage.memory.extraEnv }}
{{- toYaml .Values.storage.memory.extraEnv }}
{{- end }}
{{- end -}}


{{/*
Elasticsearch related environment variables
*/}}
{{- define "elasticsearch.env" -}}
{{- if or .Values.provisionDataStore.elasticsearch (eq .Values.storage.type "elasticsearch") -}}
{{- $es := .Values.storage.elasticsearch | default dict -}}
{{- $scheme := $es.scheme | default "http" -}}
{{- $port := $es.port | default 9200 -}}
{{- $user := $es.user | default "elastic" -}}
{{- $password := .Values.elasticsearch.secret.password | default "changeme" -}}
- name: ES_SERVER_URLS
  value: "{{ $scheme }}://elasticsearch-master:{{ $port }}"
- name: ES_USERNAME
  value: {{ $user | quote }}
- name: ES_PASSWORD
  value: {{ $password | quote }}
{{- /* Handle TLS insecurity */ -}}
{{- if or ( and $es.tls ( $es.tls.insecure ) ) ( eq $scheme "https" ) }}
  {{- if $es.tls }}
    {{- if $es.tls.insecure }}
- name: ES_TLS_SKIP_HOST_VERIFY
  value: "true"
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Cassandra, Elasticsearch, or grpc-plugin, badger, memory related environment variables depending on which is used
*/}}
{{- define "storage.env" -}}
{{- if eq .Values.storage.type "cassandra" -}}
{{ include "cassandra.env" . }}
{{- else if or (eq .Values.storage.type "elasticsearch") .Values.provisionDataStore.elasticsearch -}}
{{ include "elasticsearch.env" . }}
{{- else if or (eq .Values.storage.type "grpc-plugin") (eq .Values.storage.type "grpc") -}}
{{ include "grpcPlugin.env" . }}
{{- else if eq .Values.storage.type "badger" -}}
{{ include "badger.env" . }}
{{- else if eq .Values.storage.type "memory" -}}
{{ include "memory.env" . }}
{{- end -}}
{{- end -}}

{{/*
Cassandra related command line options
*/}}
{{- define "cassandra.cmdArgs" -}}
{{- range $key, $value := .Values.storage.cassandra.cmdlineParams -}}
{{- if $value }}
- --{{ $key }}={{ $value }}
{{- else }}
- --{{ $key }}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
Cassandra or Elasticsearch related command line options depending on which is used
*/}}
{{- define "storage.cmdArgs" -}}
{{- if eq .Values.storage.type "cassandra" -}}
{{- include "cassandra.cmdArgs" . -}}
{{- else if eq .Values.storage.type "elasticsearch" -}}
# No specific helper, usage depends on args
{{- end -}}
{{- end -}}


{{/*
Provides a basic ingress network policy
*/}}
{{- define "jaeger.ingress.networkPolicy" -}}
apiVersion: {{ include "common.capabilities.networkPolicy.apiVersion" . }}
kind: NetworkPolicy
metadata:
  name: {{ printf "%s-ingress" .Name }}
  namespace: {{ .Release.Namespace }}
  labels:
    app.kubernetes.io/component: {{ .Component }}
    {{- include "jaeger.labels" . | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/component: {{ .Component }}
  policyTypes:
  - Ingress
  ingress:
  {{- if or .ComponentValues.networkPolicy.ingressRules.namespaceSelector .ComponentValues.networkPolicy.ingressRules.podSelector }}
  - from:
    {{- if .ComponentValues.networkPolicy.ingressRules.namespaceSelector }}
    - namespaceSelector:
        matchLabels: {{- include "common.tplvalues.render" (dict "value" .ComponentValues.networkPolicy.ingressRules.namespaceSelector "context" $) | nindent 10 }}
    {{- end }}
    {{- if .ComponentValues.networkPolicy.ingressRules.podSelector }}
    - podSelector:
        matchLabels: {{- include "common.tplvalues.render" (dict "value" .ComponentValues.networkPolicy.ingressRules.podSelector "context" $) | nindent 10 }}
    {{- end }}
  {{- end }}
  {{- if .ComponentValues.networkPolicy.ingressRules.customRules }}
  {{- include "common.tplvalues.render" (dict "value" .ComponentValues.networkPolicy.ingressRules.customRules "context" $) | nindent 2 }}
  {{- end }}
{{- end -}}

{{/*
Provides a basic egress network policy
*/}}
{{- define "jaeger.egress.networkPolicy" -}}
apiVersion: {{ include "common.capabilities.networkPolicy.apiVersion" . }}
kind: NetworkPolicy
metadata:
  name: {{ printf "%s-egress" .Name }}
  namespace: {{ .Release.Namespace }}
  labels:
    app.kubernetes.io/component: {{ .Component }}
    {{- include "jaeger.labels" . | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/component: {{ .Component }}
  policyTypes:
  - Egress
  egress:
  {{- if or .ComponentValues.networkPolicy.egressRules.namespaceSelector .ComponentValues.networkPolicy.egressRules.podSelector }}
  - to:
    {{- if .ComponentValues.networkPolicy.egressRules.namespaceSelector }}
    - namespaceSelector:
        matchLabels: {{- include "common.tplvalues.render" (dict "value" .ComponentValues.networkPolicy.egressRules.namespaceSelector "context" $) | nindent 10 }}
    {{- end }}
    {{- if .ComponentValues.networkPolicy.egressRules.podSelector }}
    - podSelector:
        matchLabels: {{- include "common.tplvalues.render" (dict "value" .ComponentValues.networkPolicy.egressRules.podSelector "context" $) | nindent 10 }}
    {{- end }}
  {{- end }}
  {{- if .ComponentValues.networkPolicy.egressRules.customRules }}
  {{- include "common.tplvalues.render" (dict "value" .ComponentValues.networkPolicy.egressRules.customRules "context" $) | nindent 2 }}
  {{- end }}
{{- end -}}

{{/*
Create image name value
If not tag is provided, it defaults to .Chart.AppVersion.
( dict "imageRoot" .Values.path.to.image "context" $ )
*/}}
{{- define "renderImage" -}}
{{- $image := merge .imageRoot (dict "tag" .context.Chart.AppVersion) -}}
{{- include "common.images.image" (dict "imageRoot" $image "global" .context.Values.global) -}}
{{- end -}}

{{/*
Create image name for jaeger image
*/}}
{{- define "jaeger.image" -}}
{{- include "renderImage" ( dict "imageRoot" .Values.jaeger.image "context" $ ) -}}
{{- end -}}

{{/*
Create pull secrets for jaeger image
*/}}
{{- define "jaeger.imagePullSecrets" -}}
{{- include "common.images.renderPullSecrets" (dict "images" (list .Values.jaeger.image) "context" $) -}}
{{- end }}

{{/*
Create image name for spark image
*/}}
{{- define "spark.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.spark.image "global" .Values.global) -}}
{{- end -}}

{{/*
Create pull secrets for spark image
*/}}
{{- define "spark.imagePullSecrets" -}}
{{- include "common.images.renderPullSecrets" (dict "images" (list .Values.spark.image) "context" $) -}}
{{- end }}

{{/*
Create image name for esIndexCleaner image
*/}}
{{- define "esIndexCleaner.image" -}}
{{- include "renderImage" ( dict "imageRoot" .Values.esIndexCleaner.image "context" $ ) -}}
{{- end -}}

{{/*
Create pull secrets for esIndexCleaner image
*/}}
{{- define "esIndexCleaner.imagePullSecrets" -}}
{{- include "common.images.renderPullSecrets" (dict "images" (list .Values.esIndexCleaner.image) "context" $) -}}
{{- end }}

{{/*
Create image name for esRollover image
*/}}
{{- define "esRollover.image" -}}
{{- include "renderImage" ( dict "imageRoot" .Values.esRollover.image "context" $ ) -}}
{{- end -}}

{{/*
Create pull secrets for esRollover image
*/}}
{{- define "esRollover.imagePullSecrets" -}}
{{- include "common.images.renderPullSecrets" (dict "images" (list .Values.esRollover.image) "context" $) -}}
{{- end }}

{{/*
Create image name for esLookback image
*/}}
{{- define "esLookback.image" -}}
{{- include "renderImage" ( dict "imageRoot" .Values.esLookback.image "context" $ ) -}}
{{- end -}}

{{/*
Create pull secrets for esLookback image
*/}}
{{- define "esLookback.imagePullSecrets" -}}
{{- include "common.images.renderPullSecrets" (dict "images" (list .Values.esLookback.image) "context" $) -}}
{{- end }}


{{- define "jaeger.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}

{{/*
Generate command line arguments from a dictionary
*/}}
{{- define "extra.cmdArgs" -}}
{{- range $key, $value := .cmdlineParams -}}
{{- if $value }}
- --{{ $key }}={{ $value }}
{{- else }}
- --{{ $key }}
{{- end -}}
{{- end -}}
{{- end -}}
