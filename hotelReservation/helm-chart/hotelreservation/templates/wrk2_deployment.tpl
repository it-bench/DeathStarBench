apiVersion: apps/v1
kind: Deployment
metadata:
  name: wrk2-{{ include "hotel-reservation.fullname" . }}
spec:
  replicas: {{ .Values.wrk2.replicas }}
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
          command:
            - "/bin/sh"
            - "-c"
            - |
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
              value: "{{ .Values.loadgen.numThreads }}"
            - name: WRK2_CONNS
              value: "{{ .Values.loadgen.numConns }}"
            - name: WRK2_DURATION
              value: "{{ .Values.loadgen.duration }}"
            - name: WRK2_REQUESTS_PER_SEC
              value: "{{ .Values.loadgen.requestsPerSec }}"
            - name: WRK2_TARGET_URL
              value: "http://frontend-{{ include "hotel-reservation.fullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.serviceDnsDomain }}:5000"
            - name: WRK2_SCRIPT_PATH
              value: "{{ .Values.loadgen.scriptPath }}"
      restartPolicy: Always