# ============ SIMPLIFIED VPC AND EKS FOR CHAT-APP ==============

# =============== VPC MODULE ===============
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = var.tags
}

# ================ SIMPLIFIED EKS MODULE ===============
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  
  # Use EKS-managed security groups (no custom override)
  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  # Add chat-app specific rules to EKS-managed node security group
  node_security_group_additional_rules = {
    # CRITICAL: Allow all inter-node communication
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    
    # CRITICAL: Allow ICMP between nodes for troubleshooting
    ingress_icmp = {
      description = "ICMP between nodes"
      protocol    = "icmp"
      from_port   = -1
      to_port     = -1
      type        = "ingress"
      cidr_blocks = [var.vpc_cidr]
    }
    
    # CHAT-APP: Frontend HTTP access
    ingress_http = {
      description = "HTTP access for chat-app frontend"
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    
    # CHAT-APP: Backend API access
    ingress_backend = {
      description = "Chat-app backend API"
      protocol    = "tcp"
      from_port   = 5001
      to_port     = 5001
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    
    # NodePort range for ingress-nginx and services
    ingress_nodeport = {
      description = "NodePort range for Kubernetes services"
      protocol    = "tcp"
      from_port   = 30000
      to_port     = 32767
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    
    # Health check port for load balancer
    ingress_health_check = {
      description = "Load balancer health check port"
      protocol    = "tcp"
      from_port   = 10254
      to_port     = 10254
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  eks_managed_node_groups = {
    example = {
      ami_type       = var.ami_type
      instance_types = var.instance_types

      min_size     = 2
      max_size     = 4
      desired_size = 2

      # No additional custom security groups needed!
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# ================ ArgoCD SETUP ===============
resource "time_sleep" "wait_for_cluster" {
  create_duration = "60s"
}

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.51.6"

  values = [
    yamlencode({
      server = {
        service = {
          type = "ClusterIP"
        }
        ingress = {
          enabled = false
        }
        extraArgs = ["--insecure"]
      }

      controller = {
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }

      repoServer = {
        resources = {
          requests = {
            cpu    = "50m"
            memory = "64Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }
      }

      redis = {
        resources = {
          requests = {
            cpu    = "50m"
            memory = "64Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "128Mi"
          }
        }
      }
    })
  ]

  depends_on = [time_sleep.wait_for_cluster]
}

resource "time_sleep" "wait_for_argocd" {
  create_duration = "60s"
  depends_on      = [helm_release.argocd]
}
