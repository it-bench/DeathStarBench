apiVersion: apps/v1
kind: Deployment
metadata:
  name: otel-collector
spec:
  replicas: 1
  selector:
    matchLabels:
      app: otel-collector
  template:
    metadata:
      labels:
        app: otel-collector
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
            name: otel-collector-config
      restartPolicy: Always