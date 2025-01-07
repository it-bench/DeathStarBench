{{- define "hotelreservation.templates.wrk2-deployment" }}
{{ $fullname := include "hotel-reservation.fullname" . }}
{{- if eq (toString $.Values.global.services.environments.TLS) "1" }}
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: wrk2-{{ $fullname }}-certificates
data:
  {{ ($.Files.Glob "ca_cert.pem").AsSecrets | indent 2 }}
---
{{- end }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wrk2-{{ include "hotel-reservation.fullname" . }}
spec:
  replicas: {{ $.Values.wrk2.replicas }}
  selector:
    matchLabels:
      app: wrk2-{{ include "hotel-reservation.fullname" . }}
  template:
    metadata:
      labels:
        app: wrk2-{{ include "hotel-reservation.fullname" . }}
    spec:
      containers:
        - name: wrk2
          image: "saurabhjha1/hotelreswrk2:latest"
          {{- if eq (toString $.Values.global.services.environments.TLS) "1" }}
          volumeMounts: 
          - name: "ca-certificate"
            readOnly: true
            mountPath: /wrk2/certificates
          {{- end }}
          command:
            - "/bin/sh"
            - "-c"
            - |
              {{- if eq (toString $.Values.global.services.environments.TLS) "1" }}
              cp -r certificates /usr/share/ca-certificates/custom-ca
              echo custom-ca/ca_cert.pem >> /etc/ca-certificates.conf
              update-ca-certificates
              {{- end }}
              while true; do
                ../wrk2/wrk -D exp \
                -t ${WRK2_THREADS} \
                -c ${WRK2_CONNS} \
                -d ${WRK2_DURATION} \
                -L \
                -s ${WRK2_SCRIPT_PATH} \
                ${WRK2_TARGET_URL} \
                -R ${WRK2_REQUESTS_PER_SEC};
                sleep 10;
              done
          env:
            - name: WRK2_THREADS
              value: "{{ $.Values.loadgen.numThreads }}"
            - name: WRK2_CONNS
              value: "{{ $.Values.loadgen.numConns }}"
            - name: WRK2_DURATION
              value: "{{ $.Values.loadgen.duration }}"
            - name: WRK2_REQUESTS_PER_SEC
              value: "{{ $.Values.loadgen.requestsPerSec }}"
            - name: WRK2_TARGET_URL
              {{- if eq (toString $.Values.global.services.environments.TLS) "1" }}
              value: "https://frontend-{{ include "hotel-reservation.fullname" . }}.{{ .Release.Namespace }}.svc.{{ $.Values.global.serviceDnsDomain }}:5000"
              {{- else }}
              value: "http://frontend-{{ include "hotel-reservation.fullname" . }}.{{ .Release.Namespace }}.svc.{{ $.Values.global.serviceDnsDomain }}:5000"
              {{- end }}
            - name: WRK2_SCRIPT_PATH
              value: "{{ $.Values.loadgen.scriptPath }}"
      {{- if eq (toString $.Values.global.services.environments.TLS) "1" }}
      volumes:
      - name: "ca-certificate"
        secret:
          secretName: wrk2-{{ $fullname }}-certificates
      {{- end }}
      restartPolicy: Always
{{- end }}
