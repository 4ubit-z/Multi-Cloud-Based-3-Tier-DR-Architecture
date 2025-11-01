resource "aws_eks_cluster" "eks_cluster1" { #eks 클러스터 생성
    name = var.eks_cluster_1
    role_arn = var.sso_role_name
    version = "1.30"

        
    vpc_config {
      endpoint_private_access = true
      endpoint_public_access = true
      subnet_ids = [
        aws_subnet.private_1a.id,
        aws_subnet.private_2b.id,
        aws_subnet.private_3c.id
        ]
      security_group_ids = [aws_security_group.sg_eks_cluster.id]

    }
    depends_on = [ 
      aws_iam_role_policy_attachment.eks_cluster_policy,
      aws_iam_role_policy_attachment.eks_vpc_controller
     ]

}

resource "aws_eks_node_group" "eks_node1" { #노드그룹 생성
    cluster_name = aws_eks_cluster.eks_cluster1.name
    node_group_name = "eks_node1"
    node_role_arn = var.sso_role_name
    subnet_ids = [
        aws_subnet.private_1a.id,
        aws_subnet.private_2b.id,
        aws_subnet.private_3c.id
    ]

    scaling_config {
      desired_size = var.eks_cluster1_desired_node_count #3
      min_size = var.eks_cluster1_min_node_count #3
      max_size = var.eks_cluster1_max_node_count #6
    }
    instance_types = ["t3.medium"]
    disk_size = 30
    capacity_type = "ON_DEMAND"

    depends_on = [ 
      aws_iam_role_policy_attachment.node_worker,
      aws_iam_role_policy_attachment.node_cni,
      aws_iam_role_policy_attachment.node_ecr_ro
     ]


}


# 에드온

# CNI 애드온 - Pod에 IP를 할당하는 네트워크 플러그인
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.eks_cluster1.name
  addon_name   = "vpc-cni"
}
# kube-proxy 애드온 - Service 트래픽 처리
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.eks_cluster1.name
  addon_name   = "kube-proxy"
}
# CoreDNS 애드온 - 클러스터 내부 DNS
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.eks_cluster1.name
  addon_name   = "coredns"
}