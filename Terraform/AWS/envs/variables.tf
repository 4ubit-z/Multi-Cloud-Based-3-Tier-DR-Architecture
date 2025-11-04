variable "project_name" {
  description = "multi_cloud_dr"
}


variable "region" {
  description = "region"
  default = "ap-northeast-2"
}

variable "profile" {
  description = "profile"
  default = "tf_member1-sso"
}

variable "sso_session" {
  default = "aubit-sso-session"
}

variable "sso_start_url" {
  default = "https://d-9b676a3049.awsapps.com/start"
}

variable "sso_region" {
  default = "ap-northeast-2"
}

variable "sso_account_id" {
  default = "867344475403"
}

variable "sso_role_name" {
  default = "PowerUserAccess"
}
###########################################################################
#vpc/Network variable

variable "vpc_1_cidr" {
  description = "first vpc"
  type = string
  default = "10.0.0.0/16"
}



# Subnet
variable "public_subnets" {
  description = "public subnet CIDR list"
  type        = list(string)
  default     = [
    "10.0.10.0/24", # ap-northeast-2a
    "10.0.11.0/24", # ap-northeast-2b
  ]
  
}
variable "private_subnets" {
  description = "private subnet CIDR list"
  type        = list(string)
  default     = [
    "10.0.1.0/24", # ap-northeast-2a
    "10.0.2.0/24", # ap-northeast-2b
  ]
}












###########################################################################

#eks

variable "eks_cluster_1" {
  default = "eks_cluster1"
}
variable "eks_role" {
  default = "eks_role"
}

# eks_setting variable
variable "eks_cluster1_desired_node_count" {
  description = "default_node_count"
  type = number
  default = 1
}
variable "eks_cluster1_min_node_count" {
  description = "min_node_count"
  type = number
  default = 1
}
variable "eks_cluster1_max_node_count" {
  description = "max_node_count"
  type = number
  default = 3
}



###########################################################################
#eks_role

variable "eks_iam_policy_json" {
  description = "EKS IAM 정책 JSON"
  type        = string
  default = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EKSRoleLifecycle",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRole",
        "iam:ListAttachedRolePolicies",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile"
      ],
      "Resource": "arn:aws:iam::*:role/eks_*"
    },
    {
      "Sid": "PassOnlyEKSAndEC2",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "arn:aws:iam::*:role/eks_*",
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": [
            "eks.amazonaws.com",
            "ec2.amazonaws.com"
          ]
        }
      }
    },
    {
      "Sid": "ServiceLinkedRolesForEKS",
      "Effect": "Allow",
      "Action": [
        "iam:CreateServiceLinkedRole",
        "iam:GetRole"
      ],
      "Resource": [
        "arn:aws:iam::*:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS*",
        "arn:aws:iam::*:role/aws-service-role/eks-nodegroup.amazonaws.com/*",
        "arn:aws:iam::*:role/aws-service-role/eks-fargate.amazonaws.com/*",
        "arn:aws:iam::*:role/aws-service-role/elasticloadbalancing.amazonaws.com/*",
        "arn:aws:iam::*:role/aws-service-role/eks.amazonaws.com/*"
      ]
    },
    {
      "Sid": "OIDCForIRSAIfNeeded",
      "Effect": "Allow",
      "Action": [
        "iam:CreateOpenIDConnectProvider",
        "iam:DeleteOpenIDConnectProvider",
        "iam:TagOpenIDConnectProvider",
        "iam:UntagOpenIDConnectProvider"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}