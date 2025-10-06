# ======== VPC OUTPUTS ==========

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "vpc_cidr_block" {
  value = module.vpc.vpc_cidr_block
}

# ========= EKS OUTPUTS ========

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority" {
  description = "EKS cluster certificate authority"
  value       = module.eks.cluster_certificate_authority_data
}

output "eks_node_group_role_arn" {
  description = "IAM role ARN of the EKS node group"
  value = module.eks.eks_managed_node_groups["example"].iam_role_arn

}
