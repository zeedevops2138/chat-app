resource "aws_security_group" "nodes_sg" {
  name        = "${var.cluster_name}-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_cluster_sg.id]
    description = "Allow HTTP access to the nodes"
  
}

  ingress {
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    security_groups= [aws_security_group.eks_cluster_sg.id]
    description = "Allow access to the metrics server"
  } 

   ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    self            = true
    description     = "Allow all inter-node communication"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  } 

  tags = var.tags
}