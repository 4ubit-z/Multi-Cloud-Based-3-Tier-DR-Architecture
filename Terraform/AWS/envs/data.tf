data "aws_caller_identity" "me" {}

data "aws_region" "current" {}

data "aws_iam_role" "eks_auto_cluster_role" {
  name = "AmazonEKSAutoClusterRole"
}
data "aws_iam_role" "eks_nodegroup_role" {
  name = "eks-nodegroup-policy" 
}

#에드온 버전 조회
data "aws_eks_addon_version" "coredns" {
  addon_name         = "coredns"
  kubernetes_version = aws_eks_cluster.eks_cluster1.version
  most_recent        = true
}