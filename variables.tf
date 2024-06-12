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
  default     = "f1.2xlarge"
}

# A little buggy at the moment
# ami-02ab431c7b3297b00
# "resolve:ssm:/aws/service/marketplace/prod-gimv3gqbpe57k/latest"
variable "ami_id" {
  description = "The AMI ID for the FPGA Developer AMI"
  type        = string
  default     = "ami-02ab431c7b3297b00"
}

variable "spot_price" {
  description = "The maximum price to pay for the spot instance"
  type        = string
  default     = "0.05"
}

variable "use_spot_instance" {
  description = "Whether to use a spot instance"
  type        = bool
  default     = false
}
