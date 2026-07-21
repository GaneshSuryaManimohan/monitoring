variable "security_group_ids" {
  description = "List of security groups used"
  type        = list(string)
  # default = [ "sg-0123456789abcdef0" ]
}

variable "prometheus_iam_instance_profile" {
  description = "IAM instance profile for Prometheus"
  type        = string
}

variable "instances" {
  description = "List of instance names to create"
  type        = list(string)
  default     = ["prometheus", "node-1", "node-2", "frontend", "elk"]
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "subnet_id" {
  description = "Subnet ID to launch the instances in (optional - leave null to use default VPC/subnet behavior)"
  type        = string
  default     = null
}

# variable "prometheus_iam_instance_profile" {
#     description = "IAM instance profile for Prometheus"
#     type = string
#     default = "PrometheusEC2Describe"
# }



# security_group_ids = [ "sg-0123456789abcdef0" ]