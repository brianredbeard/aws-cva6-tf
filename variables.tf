variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.250.248.0/22"
}

variable "subnet_cidr" {
  description = "The CIDR block for the subnet"
  type        = string
  default     = "10.250.250.0/24"
}

variable "instance_type" {
  description = "The type of instance to use"
  type        = string
  #default     = "f1.2xlarge"
  default = "t3.large"
}

# AWS F1 Development AMI:
# "/aws/service/marketplace/prod-44rhn3lsk7ft2"
# Centos 7 AMI:
# "/aws/service/marketplace/prod-a77hqdkwpdk3o"
# These can be verified with the AWS CLI command:
#   aws ssm get-parameters-by-path --path "/aws/service/marketplace/prod-a77hqdkwpdk3o/"
variable "marketplace_id" {
  description = "The AMI ID for the FPGA Developer AMI"
  type        = string
  default     = "/aws/service/marketplace/prod-44rhn3lsk7ft2"
}

variable "spot_price" {
  description = "The maximum price to pay for the spot instance"
  type        = string
  default     = null
}

variable "use_spot_instance" {
  description = "Whether to use a spot instance"
  type        = bool
  default     = false
}
