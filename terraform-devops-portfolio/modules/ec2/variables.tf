variable "env" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "instance_type" {
  description = "EC2 instance type — t2.micro is free tier eligible"
  type        = string
  default     = "t3.small"
}

variable "worker_count" {
  description = "Number of K3s worker nodes"
  type        = number
  default     = 2
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "master_sg_id" {
  type = string
}

variable "worker_sg_id" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "public_key_path" {
  description = "Path to your SSH public key file"
  type        = string
  default     = "~/.ssh/k3s-key.pub"
}

variable "tags" {
  type    = map(string)
  default = {}
}
