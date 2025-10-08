# ========== VPC VARIABLES =========

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
  default     = "vpc"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]  
}
variable "tags" {
  description = "Tags to apply to the VPC and its resources"
  type        = map(string)
  default     = {
    Terraform   = "true"
    Environment = "dev"
  } 
}


# ========= EKS VARIABLES =========

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "Eks-cluster"
}

variable "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "ami_type" {
  description = "The AMI type for EKS managed node groups"
  type        = string
  default     = "AL2023_x86_64_STANDARD"  
}
variable "instance_types" {
  description = "The instance types for EKS managed node groups"
  type        = list(string)
  default     = ["t2.medium"]
  
}