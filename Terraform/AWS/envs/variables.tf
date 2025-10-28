variable "region" {
  default = "ap-northeast-2"
}

variable "profile" {
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



#eks

variable "eks_cluster_1" {
  default = "eks_cluster1"
}
variable "eks_role" {
  default = "eks_role"
}