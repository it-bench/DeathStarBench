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
    spec:
      containers:
      - name: "{{ .Values.container.name }}"
        image: "{{ .Values.container.image }}:{{ .Values.container.imageVersion }}"
        {{- if .Values.useAccessControl }}
        args:
        - "--auth"
        {{- end }}
        volumeMounts:
        - name: {{ .Values.name }}-{{ include "hotel-reservation.fullname" . }}-path
          mountPath: /data/db
        {{- if .Values.useInitScript }}
        - name: init-script
          mountPath: /docker-entrypoint-initdb.d
        {{- end }}
      volumes:
      - name: {{ .Values.name }}-{{ include "hotel-reservation.fullname" . }}-path
        emptyDir: {}
      {{- if .Values.useInitScript }}
      - name: init-script
        configMap:
          name: {{ .Values.initScriptConfigMap }}
      {{- end }}
{{- end }}
