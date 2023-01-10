{{/*
MIT License

Copyright (c) 2020-2022 F5, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/}}

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
Return capabilities required for daemonset agent pods
*/}}
{{- define "threatstack-agent.daemonset-capabilities" -}}
{{- $ebpf_caps := list "SYS_RESOURCE" "IPC_LOCK" -}}
{{- if .Values.ebpfEnabled -}}
{{- $cap_list := concat .Values.capabilities $ebpf_caps -}}
{{- range $cap_list -}}"{{- . -}}", {{ end -}}
{{- else -}}
{{- range .Values.capabilities -}}"{{- . -}}", {{ end -}}
{{- end -}}
{{- end -}}

{{/*
Return capabilities required for api-reader pod
*/}}
{{- define "threatstack-agent.apireader-capabilities" -}}
{{- range .Values.capabilities -}}"{{- . -}}", {{ end -}}
{{- end -}}

{{/*
Return higher memory limit for agent if OpenShift is enabled
*/}}
{{- define "threatstack-agent.daemonset-openshift-default-memlimit" -}}
{{- if .Values.openShift -}}
{{- "1Gi" -}}
{{- else -}}
{{- "512Mi" -}}
{{- end -}}
{{- end -}}

{{/*
Return eBPF configuration required if enabled
*/}}
{{- define "threatstack-agent.daemonset-ebpf-config" -}}
{{- if .Values.ebpfEnabled -}}
{{- "enable_bpf_sensors true" -}}
{{- else -}}
{{- "enable_bpf_sensors false" -}}
{{- end -}}
{{- end -}}

{{/*
Return Low Power Mode configuration required if enabled
*/}}
{{- define "threatstack-agent.daemonset-lowPowerMode-config" -}}
{{- if .Values.daemonset.enableLowPowerMode -}}
{{- "low_power true" -}}
{{- else -}}
{{- "low_power false" -}}
{{- end -}}
{{- end -}}

{{/*
Return runtime config if docker is disabled
*/}}
{{- define "threatstack-agent.docker-config" -}}
{{- if kindIs "invalid" .Values.daemonset.enableDocker -}}
{{- else -}}
{{- if eq .Values.daemonset.enableDocker false -}}
{{- default "container_runtimes.docker.enabled false container_runtimes.docker.kubernetes_enabled false" -}}
{{- else -}}
{{- default "container_runtimes.docker.enabled true container_runtimes.docker.kubernetes_enabled true" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return runtime config if containerd is disabled
*/}}
{{- define "threatstack-agent.containerd-config" -}}
{{- if kindIs "invalid" .Values.daemonset.enableContainerd -}}
{{- else -}}
{{- if eq .Values.daemonset.enableContainerd false -}}
{{- default "container_runtimes.containerd.enabled false container_runtimes.containerd.kubernetes_enabled false" -}}
{{- else -}}
{{- default "container_runtimes.containerd.enabled true container_runtimes.containerd.kubernetes_enabled true" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return runtime config if CRI-O is disabled
*/}}
{{- define "threatstack-agent.crio-config" -}}
{{- if kindIs "invalid" .Values.daemonset.enableCrio -}}
{{- else -}}
{{- if eq .Values.daemonset.enableCrio false -}}
{{- default "container_runtimes.crio.enabled false" -}}
{{- else -}}
{{- default "container_runtimes.crio.enabled true" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return Service Account Name if rbac is enabled
*/}}
{{- define "threatstack-agent.serviceAccountName" -}}
{{- if .Values.rbac.create -}}
{{ include "threatstack-agent.name" . }}
{{- else -}}
{{ .Values.rbac.serviceAccountName }}
{{- end -}}
{{- end -}}

{{/*
Return Additional Runtime Config for Daemonset
*/}}
{{- define "threatstack-agent.daemonset-runtimeConfig" -}}
{{- $runtimeConfig := list (include "threatstack-agent.docker-config" .) (include "threatstack-agent.containerd-config" .) (include "threatstack-agent.crio-config" .) -}}
{{- $runtimeConfig = append $runtimeConfig (include "threatstack-agent.daemonset-lowPowerMode-config" .) -}}
{{- $runtimeConfig = append $runtimeConfig (include "threatstack-agent.daemonset-ebpf-config" .) -}}
{{- $runtimeConfig = append $runtimeConfig .Values.daemonset.additionalRuntimeConfig -}}

{{ $runtimeConfig | join " " }}
{{- end -}}
