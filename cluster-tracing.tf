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

resource "kubectl_manifest" "otel" {
  count      = var.cluster_configuration.tracing_stack.preinstall ? 1 : 0
  depends_on = [kubernetes_namespace.monitoring]
  yaml_body  = file("${path.module}/templates/manifests/otel-deployment.yaml")
}

resource "kubectl_manifest" "otel_svc" {
  count      = var.cluster_configuration.tracing_stack.preinstall ? 1 : 0
  depends_on = [kubernetes_namespace.monitoring]
  yaml_body  = file("${path.module}/templates/manifests/otel-service.yaml")
}

resource "kubectl_manifest" "config" {
  count      = var.cluster_configuration.tracing_stack.preinstall ? 1 : 0
  depends_on = [kubernetes_namespace.monitoring]
  yaml_body  = file("${path.module}/templates/manifests/otel-configmap.yaml")
}
