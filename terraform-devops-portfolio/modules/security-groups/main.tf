# ------------------------------------------------------------------
# Security group for K3s master node
# ------------------------------------------------------------------
resource "aws_security_group" "k3s_master" {
  name        = "${var.env}-k3s-master-sg"
  description = "Security group for K3s master node"
  vpc_id      = var.vpc_id

  # SSH — restrict to your IP in production
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
    description = "SSH access"
  }

  # K3s API server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kubernetes API server"
  }

  # HTTP/HTTPS for deployed apps
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  # Flannel VXLAN (K3s CNI)
  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    self        = true
    description = "Flannel VXLAN between nodes"
  }

  # Allow all within the SG (node-to-node)
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound"
  }

  tags = merge(var.tags, { Name = "${var.env}-k3s-master-sg" })
}

# ------------------------------------------------------------------
# Security group for K3s worker nodes
# ------------------------------------------------------------------
resource "aws_security_group" "k3s_worker" {
  name        = "${var.env}-k3s-worker-sg"
  description = "Security group for K3s worker nodes"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
    description = "SSH access"
  }

  # NodePort range
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kubernetes NodePort services"
  }

  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    self        = true
    description = "Flannel VXLAN"
  }

  ingress {
    from_port                = 0
    to_port                  = 0
    protocol                 = "-1"
    source_security_group_id = aws_security_group.k3s_master.id
    description              = "All traffic from master"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.env}-k3s-worker-sg" })
}
