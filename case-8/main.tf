# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 21.0"

#   name               = "demo-eks-cluster"
#   kubernetes_version = "1.33"

#   # Optional
#     endpoint_public_access = true 
#   endpoint_private_access = true

#   # Optional: Adds the current caller identity as an administrator via cluster access entry
#   enable_cluster_creator_admin_permissions = true

#   compute_config = {
#     enabled    = true
#     node_pools = ["general-purpose"]
#   }

#   vpc_id     = "vpc-1234556abcdef"
#   subnet_ids = ["subnet-abcde012", "subnet-bcde012a", "subnet-fghi345a"]

#   tags = {
#     Environment = "dev"
#     Terraform   = "true"
#   }
# }