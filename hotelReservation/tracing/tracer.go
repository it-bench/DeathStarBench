package tracing

import (
    "os"
    "strconv"
    "time"
    opentracing "github.com/opentracing/opentracing-go"
    "github.com/rs/zerolog/log"
    "github.com/uber/jaeger-client-go/config"
)

var (
    defaultSampleRatio float64 = 0.01
)

func Init(serviceName, host string) (opentracing.Tracer, error) {
    ratio := defaultSampleRatio
    if val, ok := os.LookupEnv("JAEGER_SAMPLE_RATIO"); ok {
        ratio, _ = strconv.ParseFloat(val, 64)
        if ratio > 1 {
            ratio = 1.0
        }
    }

    var tags []opentracing.Tag
    
    // Add K8s environment variables as tags
    if podName := os.Getenv("POD_NAME"); podName != "" {
        tags = append(tags, opentracing.Tag{Key: "k8s.pod.name", Value: podName})
    }
    if namespace := os.Getenv("POD_NAMESPACE"); namespace != "" {
        tags = append(tags, opentracing.Tag{Key: "k8s.namespace.name", Value: namespace})
    }
    if nodeName := os.Getenv("NODE_NAME"); nodeName != "" {
        tags = append(tags, opentracing.Tag{Key: "k8s.node.name", Value: nodeName})
    }
    if podIP := os.Getenv("POD_IP"); podIP != "" {
        tags = append(tags, opentracing.Tag{Key: "k8s.pod.ip", Value: podIP})
    }

    log.Info().Msgf("Jaeger client: adjusted sample ratio %f", ratio)
    tempCfg := &config.Configuration{
        ServiceName: serviceName,
        Sampler: &config.SamplerConfig{
            Type:  "probabilistic",
            Param: ratio,
        },
        Reporter: &config.ReporterConfig{
            LogSpans:            false,
            BufferFlushInterval: 1 * time.Second,
            LocalAgentHostPort:  host,
        },
        Tags: tags,
    }

    log.Info().Msg("Overriding Jaeger config with env variables")
    cfg, err := tempCfg.FromEnv()
    if err != nil {
        return nil, err
    }

    tracer, _, err := cfg.NewTracer()
    if err != nil {
        return nil, err
    }
    return tracer, nil
}