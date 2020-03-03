{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "threatstack-agent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "threatstack-agent.fullname" -}}
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
{{- define "threatstack-agent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Construct the configuration arguments for the Threat Stack Agent container
*/}}
{{- define "threatstack-agent.configArgs" -}}
{{- $defaultConfigArgs := "enable_kubes 1 enable_containers 1" -}}
{{- if .Values.additionalConfig -}}
{{- printf "%s %s" $defaultConfigArgs .Values.additionalConfig -}}
{{- else -}}
{{- printf "%s" $defaultConfigArgs -}}
{{- end -}}
{{- end -}}

{{/*
Construct the configuration arguments for the Threat Stack Agent api reader container
*/}}
{{- define "threatstack-agent-kubernetes-api.configArgs" -}}
{{- $defaultConfigArgs := "enable_kubes 1 enable_kubes_master 1 enable_containers 1" -}}
{{- if .Values.additionalConfig -}}
{{- printf "%s %s" $defaultConfigArgs .Values.additionalConfig -}}
{{- else -}}
{{- printf "%s" $defaultConfigArgs -}}
{{- end -}}
{{- end -}}
