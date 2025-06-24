resource "helm_release" "prometheus" {
  name             = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "57.0.2"

  values = [
    file("../helm/prometheus-values.yaml")
  ]

  depends_on = [module.eks]
}
