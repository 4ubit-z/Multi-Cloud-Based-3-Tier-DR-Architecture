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