variable "ami_id" {
    type = string
    default = "ami-0c7217cdde317cfec"
}

variable "image" {
    type = string
    default = "t3.micro"
}

variable "ec2_tags" {
    type = map
    default = {
        name = "Machine1"
        terraform = "Ture"
        env = "Dev"
    }
}

variable "SG_name" {
    type = string
    default = "allowAll"
}

variable "ingress_to_port" {
    type = number
    default = 0
}

variable "ingress_from_port" {
    type = number
    default = 0
}

variable "egress_to_port" {
    type = number
    default = 0
}

variable "egress_from_port" {
    type = number
    default = 0
}

variable "cidr" {
    type = list
    default = ["0.0.0.0/0"]
}

variable "SG_ingress_protocal" {
    type = string
    default = "-1"
}

variable "SG_egress_protocal" {
    type = string
    default = "-1"
}

variable "SG_tags" {
    type = map
    default = {
        env = "Dev"
        project = "terraform"
        name = "allowAll_ports"
    }
}