apiVersion: apps/v1
kind: Deployment
metadata:
  name: otel-collector-{{ include "hotel-reservation.fullname" . }}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: otel-collector-{{ include "hotel-reservation.fullname" . }}
  template:
    metadata:
      labels:
        app: otel-collector-{{ include "hotel-reservation.fullname" . }}
    spec:
      serviceAccountName: otel-collector 
      containers:
        - name: otel-collector
          image: otel/opentelemetry-collector-contrib:0.85.0
          args:
            - "--config=/etc/otelcol-contrib/config.yaml"
          volumeMounts:
          - mountPath: /etc/otelcol-contrib/config.yaml
            name: data
            subPath: config.yaml
            readOnly: true
      volumes:
        - name: data
          configMap:
            name: otel-collector-config-{{ include "hotel-reservation.fullname" . }}
      restartPolicy: Always