
# Create security groups
resource "aws_security_group" "allowAll" {
  name        = var.SG_name
  description = "AllowAll VPC provide all inbound traffic and all outbound traffic"


  ingress {
    cidr_blocks = var.cidr
    from_port   = var.ingress_from_port
    protocol    = var.SG_ingress_protocal
    to_port     = var.ingress_to_port
  }
  egress {
    cidr_blocks = var.cidr
    from_port   = var.egress_from_port
    protocol    = var.SG_egress_protocal
    to_port     = var.egress_to_port
  }

  tags = var.SG_tags
}
