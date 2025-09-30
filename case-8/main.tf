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
output "defvpcid" {
  value = module.vpc.default_vpc_id
  
}
output "myvpcid" {
  value = module.vpc.vpc_id
  
}