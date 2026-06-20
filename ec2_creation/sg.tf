
# Create security groups
resource "aws_security_group" "allowAll" {
  name        = "allowAll"
  description = "AllowAll VPC provide all inbound traffic and all outbound traffic"


  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0   # from port 0 to port 0 means all ports. 
    protocol    = "-1" # -1 means all protocals
    to_port     = 0
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0    # from port 0 to port 0 means all ports. 
    protocol    = "-1" # -1 means all protocals
    to_port     = 0
  }

  tags = {
    Name = "allowAll"
  }
}
