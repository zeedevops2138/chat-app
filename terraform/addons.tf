
# ===========EKS Core Addons ============


resource "aws_eks_addon" "vpc_cni" {
  cluster_name = module.eks.cluster_name
  addon_name   = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on = [module.eks]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = module.eks.cluster_name
  addon_name   = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on = [module.eks]
}

resource "aws_eks_addon" "coredns" {
  cluster_name = module.eks.cluster_name
  addon_name   = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on = [module.eks]
}


# ======= Wait until EKS is ready ========


resource "time_sleep" "wait_for_eks" {
  create_duration = "30s"
  depends_on      = [
    aws_eks_addon.vpc_cni,
    aws_eks_addon.kube_proxy,
    aws_eks_addon.coredns
  ]
}


# ========= NGINX Ingress Controller via Helm ========


resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.13.1"
  namespace        = "ingress-nginx"
  create_namespace = true

  values = [
    yamlencode({
      controller = {
        metrics = {
          enabled = true
        }
        service = {
          type = "LoadBalancer"
        }
      }
    })
  ]

  depends_on = [time_sleep.wait_for_eks]
}


# ========= Prometheus Stack (Monitoring) ===========


resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "56.21.3"
  namespace        = "monitoring"
  create_namespace = true

  values = [
    yamlencode({
      prometheus = {
        ingress = {
          enabled           = true
          ingressClassName = "nginx"
          hosts            = ["prometheus.local"]
        }
      }
      grafana = {
        enabled = true
        ingress = {
          enabled           = true
          ingressClassName = "nginx"
          hosts            = ["grafana.local"]
        }
        adminPassword = "admin" # Change this in real environments!
      }
    })
  ]

  depends_on = [helm_release.nginx_ingress]
}

# ========= Certificate Manager ===========

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.18.2" 
  namespace        = "cert-manager"
  create_namespace = true

  values = [
    yamlencode({
      installCRDs = true
    })
  ]

  depends_on = [module.eks]
}
