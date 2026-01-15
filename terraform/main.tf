data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = var.project_name

  # Use 2 AZs for cost + simplicity in a demo
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  # /19 subnets give room for k8s + growth
  private_subnets = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 3, i)]
  public_subnets  = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 3, i + 2)]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Required tags so EKS can use subnets for LoadBalancers
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Makes it easy to manage IAM for k8s service accounts later
  enable_irsa = true

  # Demo-friendly access:
  cluster_endpoint_public_access = true

  # Keep default add-ons simple; you can add more later
  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = {}
    eks-pod-identity-agent = {}
  }

  # Managed node group (easy ops)
  eks_managed_node_groups = {
    default = {
      name = "${local.name}-ng"

      instance_types = var.node_instance_types

      desired_size = var.node_desired_size
      min_size     = var.node_min_size
      max_size     = var.node_max_size

      subnet_ids = module.vpc.private_subnets

      # Useful for scheduling & cost control
      labels = {
        role = "general"
      }

      # Reasonable defaults for demo reliability
      disk_size = 50

      # Optional: enable remote SSH if you really need it (usually skip)
      # remote_access = {
      #   ec2_ssh_key = "your-keypair-name"
      # }
    }
  }

  # Admin permissions for your current AWS identity
  # (works well for a personal demo account)
  enable_cluster_creator_admin_permissions = true
}
