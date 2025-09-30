module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "newone"
  kubernetes_version = "1.32"

  # Optional
    endpoint_public_access = true 
  endpoint_private_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    demo-eks-nodes = {

    ami_type = "AL2_x86_64"
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1

      instance_types = ["t3.medium"]

      disk_size = 100

      key_name = "awsdev" # Replace with your actual key pair name

      additional_tags = {
        Name = "demo-eks-node"
      }
    }
  }
  addons = {
    vpc-cni = {
      most_recent = true
      configuration_values = jsonencode({
        "WARM_PREFIX_TARGET" = "1"
        "ENABLE_PREFIX_DELEGATION" = true
      })
    }
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.17" # supports EKS 1.32

  cluster_name    = "demo-eks-cluster"
  cluster_version = "1.32"

  cluster_endpoint_public_access  = true
  # cluster_endpoint_private_access = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2_x86_64" # or BOTTLEROCKET_x86_64 / AL2023_x86_64
      instance_types = ["t3.medium"]
      min_size       = "1"
      max_size       = "3"
      desired_size   = "1"
      iam_role_additional_policies = {
        ecr_read = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }

      # Better IP utilization for many pods
      enable_efa = false
  }

  cluster_addons = {
    vpc-cni = {
      most_recent = true
      configuration_values = jsonencode({
        env = {
          # For better IP utilization
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    kube-proxy = { most_recent = true }
    coredns    = { most_recent = true }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }
}
}


# data "aws_eks_cluster_auth" "this" {
#   name = module.eks.cluster_name
# }
  

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}