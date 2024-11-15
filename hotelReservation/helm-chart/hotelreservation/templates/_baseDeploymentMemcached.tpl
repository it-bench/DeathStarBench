{{- define "hotelreservation.templates.baseDeploymentMemcached" }}
{{- $count :=  add .Values.global.memcached.HACount 1 | int }}
{{- range $key, $item := untilStep 1 $count 1 }}
{{- $rangeItem := $item -}}
{{- with $ }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    {{- include "hotel-reservation.labels" . | nindent 4 }}
    {{- include "hotel-reservation.backendLabels" . | nindent 4 }}
    service: {{ .Values.name }}-{{ $rangeItem }}-{{ include "hotel-reservation.fullname" . }}
  name: {{ .Values.name }}-{{ $rangeItem }}-{{ include "hotel-reservation.fullname" . }}
spec:
  replicas: {{ .Values.replicas | default .Values.global.replicas }}
  selector:
    matchLabels:
      {{- include "hotel-reservation.selectorLabels" . | nindent 6 }}
      {{- include "hotel-reservation.backendLabels" . | nindent 6 }}
      service: {{ .Values.name }}-{{ $rangeItem }}-{{ include "hotel-reservation.fullname" . }}
      app: {{ .Values.name }}-{{ $rangeItem }}-{{ include "hotel-reservation.fullname" . }}
  template:
    metadata:
      labels:
        {{- include "hotel-reservation.labels" . | nindent 8 }}
        {{- include "hotel-reservation.backendLabels" . | nindent 8 }}
        service: {{ .Values.name }}-{{ $rangeItem }}-{{ include "hotel-reservation.fullname" . }}
        app: {{ .Values.name }}-{{ $rangeItem }}-{{ include "hotel-reservation.fullname" . }}
      {{- if hasKey $.Values "annotations" }}
      annotations:
        {{ tpl $.Values.annotations . | nindent 8 | trim }}
      {{- else if hasKey $.Values.global "annotations" }}
      annotations:
        {{ tpl $.Values.global.annotations . | nindent 8 | trim }}
      {{- end }}
    spec:
      containers:
      {{- with .Values.container }}
      - name: "{{ .name }}"
        image: {{ .dockerRegistry | default $.Values.global.dockerRegistry }}/{{ .image }}:{{ .imageVersion | default $.Values.global.defaultImageVersion }}
        imagePullPolicy: {{ .imagePullPolicy | default $.Values.global.imagePullPolicy }}
        ports:
        {{- range $cport := .ports }}
        - containerPort: {{ $cport.containerPort -}}
        {{ end }}
        {{- if hasKey . "environments" }}
        env:
          # Default Kubernetes downward API environment variables
          - name: POD_IP
            valueFrom:
              fieldRef:
                fieldPath: status.podIP
          - name: POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: HOST_IP
            valueFrom:
              fieldRef:
                fieldPath: status.hostIP
          # OpenTelemetry specific environment variables
          - name: OTEL_SERVICE_NAME
            value: {{ $.Values.name | default $.Chart.Name | quote }}
          - name: OTEL_RESOURCE_ATTRIBUTES
            value: "k8s.pod.name=$(POD_NAME),k8s.namespace.name=$(NAMESPACE),k8s.node.name=$(NODE_NAME),k8s.pod.ip=$(POD_IP),service.name={{ $.Values.name | default $.Chart.Name }}"
          {{- range $variable, $value := .environments }}
          - name: {{ $variable }}
            value: {{ $value | quote }}
          {{- end }}
        {{- else if hasKey $.Values.global.memcached "environments" }}
        env:
          # Default Kubernetes downward API environment variables
          - name: POD_IP
            valueFrom:
              fieldRef:
                fieldPath: status.podIP
          - name: POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: HOST_IP
            valueFrom:
              fieldRef:
                fieldPath: status.hostIP
          # OpenTelemetry specific environment variables
          - name: OTEL_SERVICE_NAME
            value: {{ $.Values.name | default $.Chart.Name | quote }}
          - name: OTEL_RESOURCE_ATTRIBUTES
            value: "k8s.pod.name=$(POD_NAME),k8s.namespace.name=$(NAMESPACE),k8s.node.name=$(NODE_NAME),k8s.pod.ip=$(POD_IP),service.name={{ $.Values.name | default $.Chart.Name }}"
          {{- range $variable, $value := $.Values.global.memcached.environments }}
          - name: {{ $variable }}
            value: {{ $value | quote }}
          {{- end }}
        {{- end }}
        {{- if .args}}
        args:
        {{- range $arg := .args}}
        - {{ $arg | quote }}
        {{- end -}}
        {{- end }}
        {{- if .resources }}
        resources:
          {{ tpl .resources $ | nindent 10 | trim }}
        {{- else if hasKey $.Values.global "resources" }}
        resources:
          {{ tpl $.Values.global.resources $ | nindent 10 | trim }}
        {{- end }}
      {{- end -}}
      {{- if hasKey .Values "topologySpreadConstraints" }}
      topologySpreadConstraints:
        {{ tpl .Values.topologySpreadConstraints . | nindent 6 | trim }}
      {{- else if hasKey $.Values.global.memcached "topologySpreadConstraints" }}
      topologySpreadConstraints:
        {{ tpl $.Values.global.memcached.topologySpreadConstraints . | nindent 6 | trim }}
      {{- end }}
      hostname: {{ .Values.name }}-{{ include "hotel-reservation.fullname" . }}
      restartPolicy: {{ .Values.restartPolicy | default .Values.global.restartPolicy}}
      {{- if .Values.affinity }}
      affinity: {{- toYaml .Values.affinity | nindent 8 }}
      {{- else if hasKey $.Values.global "affinity" }}
      affinity: {{- toYaml .Values.global.affinity | nindent 8 }}
      {{- end }}
      {{- if .Values.tolerations }}
      tolerations: {{- toYaml .Values.tolerations | nindent 8 }}
      {{- else if hasKey $.Values.global "tolerations" }}
      tolerations: {{- toYaml .Values.global.tolerations | nindent 8 }}
      {{- end }}
      {{- if .Values.nodeSelector }}
      nodeSelector: {{- toYaml .Values.nodeSelector | nindent 8 }}
      {{- else if hasKey $.Values.global "nodeSelector" }}
      nodeSelector: {{- toYaml .Values.global.nodeSelector | nindent 8 }}
      {{- end }}
{{- end}}
{{- end}}
{{- end}}
