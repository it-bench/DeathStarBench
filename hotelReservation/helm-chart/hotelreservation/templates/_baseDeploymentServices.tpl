{{- define "hotelreservation.templates.baseDeploymentServices" }}
{{ $fullname := include "hotel-reservation.fullname" . }}
{{- if and (hasKey $.Values "tlsCertificates") (eq $.Values.global.services.environments.TLS 1) }}
{{- range $secret := $.Values.tlsCertificates }}
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: {{ $.Values.name }}-{{ $fullname }}-{{ $secret.name }}
stringData:
{{- range $certfile := $secret.certfiles }}
  {{ $certfile.name }}: |-
    {{- $.Files.Get $certfile.filename | nindent 4 -}}
{{- end }}
---
{{- end }}
{{- end }}
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    {{- include "hotel-reservation.labels" . | nindent 4 }}
    service: {{ .Values.name }}-{{ include "hotel-reservation.fullname" . }}
  name: {{ .Values.name }}-{{ include "hotel-reservation.fullname" . }}
spec:
  replicas: {{ .Values.replicas | default .Values.global.replicas }}
  selector:
    matchLabels:
      {{- include "hotel-reservation.selectorLabels" . | nindent 6 }}
      service: {{ .Values.name }}-{{ include "hotel-reservation.fullname" . }}
      app: {{ .Values.name }}-{{ include "hotel-reservation.fullname" . }}
  template:
    metadata:
      labels:
        {{- include "hotel-reservation.labels" . | nindent 8 }}
        service: {{ .Values.name }}-{{ include "hotel-reservation.fullname" . }}
        app: {{ .Values.name }}-{{ include "hotel-reservation.fullname" . }}
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
          {{- range $variable, $value := .environments }}
          - name: {{ $variable }}
            value: {{ $value | quote }}
          {{- end }}
        {{- else if hasKey $.Values.global.services "environments" }}
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
          {{- range $variable, $value := $.Values.global.services.environments }}
          - name: {{ $variable }}
            value: {{ $value | quote }}
          {{- end }}
        {{- end }}
        {{- if .command}}
        command:
        - {{ .command }}
        {{- end -}}
        {{- if .args}}
        args:
        {{- range $arg := .args}}
        - {{ $arg }}
        {{- end -}}
        {{- end }}
        {{- if .resources }}
        resources:
          {{ tpl .resources $ | nindent 10 | trim }}
        {{- else if hasKey $.Values.global "resources" }}
        resources:
          {{ tpl $.Values.global.resources $ | nindent 10 | trim }}
        {{- end }}
        {{- if or (hasKey $.Values "configMaps") (and (hasKey $.Values "tlsCertificates") (eq $.Values.global.services.environments.TLS 1)) }}
        volumeMounts: 
        {{- if $.Values.configMaps }} 
        {{- range $configMap := $.Values.configMaps }}
        - name: {{ $.Values.name }}-{{ include "hotel-reservation.fullname" $ }}-config
          mountPath: {{ $configMap.mountPath }}
          subPath: {{ $configMap.name }}
        {{- end }}
        {{- end }}
        {{- if and (hasKey $.Values "tlsCertificates") (eq $.Values.global.services.environments.TLS 1) }}
        {{- range $secret := $.Values.tlsCertificates }}
        - name: {{ $secret.name | quote }}
          readOnly: true
          mountPath: {{ $secret.mountPath | quote }}
        {{- end }}
        {{- end }}
        {{- end }}
      {{- end -}}
      {{- if or (hasKey $.Values "configMaps") (and (hasKey $.Values "tlsCertificates") (eq $.Values.global.services.environments.TLS 1)) }}
      volumes:
      {{- if $.Values.configMaps }}
      - name: {{ $.Values.name }}-{{ include "hotel-reservation.fullname" $ }}-config
        configMap:
          name: {{ $.Values.name }}-{{ include "hotel-reservation.fullname" $ }}
      {{- end }}
      {{- if and (hasKey $.Values "tlsCertificates") (eq $.Values.global.services.environments.TLS 1) }}
      {{- range $secret := $.Values.tlsCertificates }}
      - name: {{ $secret.name | quote }}
        secret:
          secretName: {{ $.Values.name }}-{{ $fullname }}-{{ $secret.name }}
      {{- end }}
      {{- end }}
      {{- end }}
      {{- if hasKey .Values "topologySpreadConstraints" }}
      topologySpreadConstraints:
        {{ tpl .Values.topologySpreadConstraints . | nindent 6 | trim }}
      {{- else if hasKey $.Values.global  "topologySpreadConstraints" }}
      topologySpreadConstraints:
        {{ tpl $.Values.global.topologySpreadConstraints . | nindent 6 | trim }}
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
