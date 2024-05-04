resource "helm_release" "tempo" {
  depends_on = [kubernetes_namespace.monitoring]
  count      = var.cluster_configuration.tracing_stack.preinstall ? 1 : 0
  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo"
  name       = "tempo"
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name
  version    = var.cluster_configuration.tracing_stack.tempo_version
  values     = [file("${path.module}/templates/values/tempo.yaml")]
}

resource "kubernetes_namespace" "otel_operator" {
  count = var.cluster_configuration.tracing_stack.preinstall ? 1 : 0
  metadata {
    name = "opentelemetry-operator-system"
  }
}

resource "helm_release" "otel_operator" {
  depends_on = [kubernetes_namespace.monitoring, helm_release.cert_manager]
  count      = var.cluster_configuration.tracing_stack.preinstall ? 1 : 0
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-operator"
  name       = "opentelemetry-operator"
  namespace  = kubernetes_namespace.otel_operator[0].metadata[0].name
  version    = var.cluster_configuration.tracing_stack.otel_operator_version
  values     = [file("${path.module}/templates/values/otel-operator.yaml")]
}

resource "kubectl_manifest" "otel_collector" {
  count      = var.cluster_configuration.tracing_stack.preinstall ? 1 : 0
  depends_on = [helm_release.otel_operator]
  yaml_body  = file("${path.module}/templates/manifests/otel-collector.yaml")
}

resource "kubectl_manifest" "otel_instrumentation" {
  count      = var.cluster_configuration.tracing_stack.preinstall ? 1 : 0
  depends_on = [helm_release.otel_operator]
  yaml_body  = file("${path.module}/templates/manifests/otel-instrumentation.yaml")
}