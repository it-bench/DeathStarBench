---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: otel-collector
  namespace: {{ .Release.Namespace }}

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  # Append namespace to make the name unique across the cluster
  name: otel-collector-{{ .Release.Namespace }}
rules:
  - apiGroups: [""]
    resources: ["pods", "namespaces", "nodes", "events"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["replicasets", "deployments", "statefulsets", "daemonsets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["batch"]
    resources: ["jobs", "cronjobs"]
    verbs: ["get", "list", "watch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  # Append namespace to make the name unique across the cluster
  name: otel-collector-{{ .Release.Namespace }}
subjects:
  - kind: ServiceAccount
    name: otel-collector
    namespace: {{ .Release.Namespace }} # Added this line to specify the namespace
roleRef:
  kind: ClusterRole
  name: otel-collector-{{ .Release.Namespace }}
  apiGroup: rbac.authorization.k8s.io
---

apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-collector-config-{{ include "hotel-reservation.fullname" . }}
data:
  config.yaml: |
    receivers:
      jaeger:
        protocols:
          grpc:
            endpoint: "0.0.0.0:14250"
          thrift_http:
            endpoint: "0.0.0.0:14268"
          thrift_compact:
            endpoint: "0.0.0.0:6831"
          thrift_binary: 
            endpoint: "0.0.0.0:6832"
      otlp:
        protocols:
          grpc:
            endpoint: "0.0.0.0:4317"
          http:
            endpoint: "0.0.0.0:4318"
            cors:
              allowed_origins:
                - "http://*"
                - "https://*"
      hostmetrics:
        scrapers:
          cpu:
            metrics:
              system.cpu.utilization:
                enabled: true
          disk:
          load:
          filesystem:
            exclude_mount_points:
              mount_points:
                - /dev/*
                - /proc/*
                - /sys/*
                - /run/k3s/containerd/*
                - /var/lib/docker/*
                - /var/lib/kubelet/*
                - /snap/*
              match_type: regexp
            exclude_fs_types:
              fs_types:
                - autofs
                - binfmt_misc
                - bpf
                - cgroup2
                - configfs
                - debugfs
                - devpts
                - devtmpfs
                - fusectl
                - hugetlbfs
                - iso9660
                - mqueue
                - nsfs
                - overlay
                - proc
                - procfs
                - pstore
                - rpc_pipefs
                - securityfs
                - selinuxfs
                - squashfs
                - sysfs
                - tracefs
              match_type: strict
          memory:
            metrics:
              system.memory.utilization:
                enabled: true
          network:
          paging:
          processes:
          process:
            mute_process_exe_error: true
            mute_process_io_error: true
      prometheus:
        config:
          scrape_configs:
            - job_name: 'otelcol'
              scrape_interval: 10s
              static_configs:
                - targets: ['0.0.0.0:8888']
    exporters:
      logging:
      otlp:
        endpoint: "{{ .Values.global.monitoring.centralJaegerAddress }}:4317"
        tls:
          insecure: true
      otlphttp/prometheus:
        endpoint: "{{ .Values.global.monitoring.centralPrometheusAddress }}"
        tls:
          insecure: true
    processors:
      batch:
      transform:
        error_mode: ignore
        trace_statements:
          - context: span
            statements:
              - replace_pattern(name, "\\?.*", "")
              - replace_match(name, "GET /api/products/*", "GET /api/products/{productId}")
      k8sattributes:
        auth_type: "serviceAccount"
        passthrough: false
        extract:
          metadata:
            - k8s.namespace.name
            - k8s.deployment.name
            - k8s.statefulset.name
            - k8s.daemonset.name
            - k8s.cronjob.name
            - k8s.job.name
            - k8s.node.name
            - k8s.pod.name
            - k8s.pod.uid
            - k8s.pod.start_time
            - container.id
          labels:
            - tag_name: key1
              key: label1
              from: pod
            - tag_name: key2
              key: label2
              from: pod
        pod_association:
          - sources:
              - from: resource_attribute
                name: k8s.pod.uid
          - sources:
              - from: resource_attribute
                name: k8s.pod.ip
          - sources:
              - from: resource_attribute
                name: host.name
          - sources:
              - from: connection
          - sources:
              - from: resource_attribute
                name: k8s.pod.name
      memory_limiter:
        check_interval: 1s
        limit_mib: 1000
        spike_limit_mib: 200
      resource:
        attributes:
        - action: insert
          from_attribute: k8s.pod.uid
          key: service.instance.id
    connectors:
      spanmetrics:
        dimensions:
          - name: "namespace"
            default: "{{ .Release.Namespace }}"
    service:
      telemetry:
        logs:
          level: "debug"
      pipelines:
        traces:
          receivers: [otlp, jaeger]
          processors: [k8sattributes, memory_limiter, resource, transform, batch]
          exporters: [otlp, logging, spanmetrics]
        metrics:
          receivers: [hostmetrics, otlp, prometheus, spanmetrics]
          processors: [k8sattributes, memory_limiter, resource, batch]
          exporters: [otlphttp/prometheus, logging]
        logs:
          receivers: [otlp]
          processors: [k8sattributes, memory_limiter, resource, batch]
          exporters: [logging]