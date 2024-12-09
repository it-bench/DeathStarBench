{{- define "hotelreservation.templates.baseDeploymentMongoDB" }}
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    {{- include "hotel-reservation.labels" . | nindent 4 }}
    {{- include "hotel-reservation.backendLabels" . | nindent 4 }}
    service: {{ .Values.name }}-{{ include "hotel-reservation.fullname" . }}
  name: {{ .Values.name }}-{{ include "hotel-reservation.fullname" . }}
spec:
  replicas: {{ .Values.replicas | default .Values.global.replicas }}
  selector:
    matchLabels:
      {{- include "hotel-reservation.selectorLabels" . | nindent 6 }}
      {{- include "hotel-reservation.backendLabels" . | nindent 6 }}
      service: {{ .Values.name }}-{{ include "hotel-reservation.fullname" . }}
      app: {{ .Values.name }}-{{ include "hotel-reservation.fullname" . }}
  template:
    metadata:
      labels:
        {{- include "hotel-reservation.labels" . | nindent 8 }}
        {{- include "hotel-reservation.backendLabels" . | nindent 8 }}
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
      - name: "{{ .Values.container.name }}"
        image: "{{ .Values.container.image }}:{{ .Values.container.imageVersion }}"
        imagePullPolicy: {{ .Values.container.imagePullPolicy | default $.Values.global.imagePullPolicy }}
        ports:
        {{- range $cport := .Values.container.ports }}
        - containerPort: {{ $cport.containerPort }}
        {{- end }}
        {{- if or .Values.useAccessControl .Values.container.args }}
        args:
        {{- if .Values.useAccessControl }}
        - "--auth"
        {{- end }}
        {{- if .Values.container.args }}
        {{- range $arg := .Values.container.args }}
        - {{ $arg }}
        {{- end }}
        {{- end }}
        {{- end }}
        {{- if .Values.container.resources }}
        resources:
          {{ tpl .Values.container.resources $ | nindent 10 }}
        {{- else if hasKey $.Values.global "resources" }}
        resources:
          {{ tpl $.Values.global.resources $ | nindent 10 }}
        {{- end }}
        volumeMounts:
        - mountPath: /data/db
          name: {{ .Values.name }}-{{ include "hotel-reservation.fullname" . }}-path
        {{- if .Values.useInitScript }}
        - name: init-script
          mountPath: /docker-entrypoint-initdb.d
        {{- end }}
      volumes:
      - name: {{ .Values.name }}-{{ include "hotel-reservation.fullname" . }}-path
        {{- if $.Values.global.mongodb.persistentVolume.enabled }}
        persistentVolumeClaim:
          claimName: {{ .Values.name }}-{{ include "hotel-reservation.fullname" . }}-pvc
        {{- else }}
        emptyDir: {}
        {{- end }}
      {{- if .Values.useInitScript }}
      - name: init-script
        configMap:
          name: {{ .Values.initScriptConfigMap }}
      {{- end }}
      {{- if .Values.affinity }}
      affinity: {{ toYaml .Values.affinity | nindent 8 }}
      {{- else if hasKey $.Values.global "affinity" }}
      affinity: {{ toYaml $.Values.global.affinity | nindent 8 }}
      {{- end }}
      {{- if .Values.tolerations }}
      tolerations: {{ toYaml .Values.tolerations | nindent 8 }}
      {{- else if hasKey $.Values.global "tolerations" }}
      tolerations: {{ toYaml $.Values.global.tolerations | nindent 8 }}
      {{- end }}
      {{- if .Values.nodeSelector }}
      nodeSelector: {{ toYaml .Values.nodeSelector | nindent 8 }}
      {{- else if hasKey $.Values.global "nodeSelector" }}
      nodeSelector: {{ toYaml $.Values.global.nodeSelector | nindent 8 }}
      {{- end }}
      {{- if hasKey .Values "topologySpreadConstraints" }}
      topologySpreadConstraints:
        {{ tpl .Values.topologySpreadConstraints . | nindent 6 }}
      {{- else if hasKey $.Values.global.mongodb "topologySpreadConstraints" }}
      topologySpreadConstraints:
        {{ tpl $.Values.global.mongodb.topologySpreadConstraints . | nindent 6 }}
      {{- end }}
{{- end }}
