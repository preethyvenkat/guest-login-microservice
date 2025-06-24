resource "helm_release" "signoz" {
  name             = "signoz"
  repository       = "https://charts.signoz.io"
  chart            = "signoz"
  namespace        = "signoz"
  create_namespace = true

  values = [
    #file("${path.module}/helm/signoz-values.yaml")
      file("../helm/signoz-values.yaml")
  ]

  depends_on = [module.eks]
}
