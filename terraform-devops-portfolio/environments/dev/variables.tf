variable "env" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "worker_count" {
  type    = number
  default = 2
}

variable "github_org" {
  description = "Your GitHub username"
  type        = string
}

variable "github_repo" {
  type    = string
  default = "terraform-devops-portfolio"
}

variable "allowed_ssh_cidrs" {
  description = "Your IP/32 — find it at whatismyip.com"
  type        = list(string)
}

variable "public_key_path" {
  type    = string
  default = "~/.ssh/k3s-key.pub"
}
