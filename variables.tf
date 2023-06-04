variable "aws_access_key_p" {
  type        = string
  sensitive   = true
}

variable "aws_secret_key_p" {
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region to create resources in"

  type        = string
  default     = "us-east-2"
}

variable "instance_type" {
  description  = "Type of AWS instance to deploy"
  type         = string
  default      = "t3.nano"
}

variable "ingress_cidr_blocks" {
  description  = "Ingress CIDR blocks to allow"
  type         = list(string)
  sensitive    = true
}

variable "ami" {
  description  = "ID of amazon machine image"
  type         = string
  default      = "ami-0f0ba639982a32edb"
}

variable "public_key" {
  description  = "Path to public key"
  type         = string
  default      = "keys/ec2.pub"
}