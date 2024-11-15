apiVersion: v1
kind: Service
metadata:
  name: otel-collector-{{ include "hotel-reservation.fullname" . }}
  labels:
    app: otel-collector-{{ include "hotel-reservation.fullname" . }}
spec:
  ports:
  - name: grpc
    port: 4317
    targetPort: 4317
    protocol: TCP
  - name: http
    port: 4318
    targetPort: 4318
    protocol: TCP
  - name: prometheus
    port: 8888
    targetPort: 8888
    protocol: TCP
  - name: jaeger-grpc
    port: 14250
    targetPort: 14250
    protocol: TCP
  - name: thrift-binary
    port: 6832
    targetPort: 6832
    protocol: UDP
  - name: thrift-compact
    port: 6831
    targetPort: 6831
    protocol: UDP
  - name: thrift-http
    port: 14268
    targetPort: 14268
    protocol: TCP
  selector:
    app: otel-collector-{{ include "hotel-reservation.fullname" . }}