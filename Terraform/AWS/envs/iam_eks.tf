#eks_control_plane role
resource "aws_iam_role" "eks_cluster_role" { 
  name = var.eks_cluster_1
  
  assume_role_policy = jsonencode({
    version = "2012-10-17",
    Statement = [{
        Effect = "Allow",
        Principal = { Service = "eks.amazonaws.com" },
        Action = "sts:AssumRole"
    }]
  })
}

# AmazonEKSClusterPolicy
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
    role = aws_iam_role.eks_cluster_role
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    # EKS control plane이 클러스터 내부의 노드/리소스와 통신할 수 있도록 하는 정책
}
# AmazonEKSVPCResourceController
resource "aws_iam_role_policy_attachment" "eks_vpc_controller" {
    role = aws_iam_role.eks_cluster_role
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
    # EKS가 VPC 안에 ENI,IP등을 관리할 수 있도록 하는 정책
}


#eks_node_group role
resource "aws_iam_role" "eks_node_role" {
  name = "eks_cluster1-node-group"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action   = "sts:AssumeRole"
    }]
  })
}

#eks_node policy
resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "node_ecr_ro" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
