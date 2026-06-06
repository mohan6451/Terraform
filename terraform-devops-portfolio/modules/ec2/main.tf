# ------------------------------------------------------------------
# Fetch latest Amazon Linux 2023 AMI
# ------------------------------------------------------------------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ------------------------------------------------------------------
# SSH key pair (generate locally: ssh-keygen -t ed25519 -f k3s-key)
# ------------------------------------------------------------------
resource "aws_key_pair" "k3s" {
  key_name   = "${var.env}-k3s-key"
  public_key = file(var.public_key_path)
  tags       = var.tags
}

# ------------------------------------------------------------------
# K3s master node
# ------------------------------------------------------------------
resource "aws_instance" "master" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_ids[0]
  vpc_security_group_ids = [var.master_sg_id]
  key_name               = aws_key_pair.k3s.key_name
  iam_instance_profile   = var.instance_profile_name

  user_data = <<-EOF
    #!/bin/bash
    set -ex

    # Install K3s server
    curl -sfL https://get.k3s.io | sh -s - server \
      --write-kubeconfig-mode 644 \
      --tls-san ${self.public_ip}

    # Wait for node-token to be generated
    until [ -f /var/lib/rancher/k3s/server/node-token ]; do sleep 2; done

    # Store token in SSM Parameter Store so workers can fetch it
    TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
    aws ssm put-parameter \
      --region ${var.aws_region} \
      --name "/${var.env}/k3s/node-token" \
      --value "$TOKEN" \
      --type SecureString \
      --overwrite || true
  EOF

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = "${var.env}-k3s-master"
    Role = "master"
  })
}

# ------------------------------------------------------------------
# K3s worker nodes
# ------------------------------------------------------------------
resource "aws_instance" "worker" {
  count                  = var.worker_count
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_ids[count.index % length(var.public_subnet_ids)]
  vpc_security_group_ids = [var.worker_sg_id]
  key_name               = aws_key_pair.k3s.key_name
  iam_instance_profile   = var.instance_profile_name

  # Workers wait for master to be ready before joining
  depends_on = [aws_instance.master]

  user_data = <<-EOF
    #!/bin/bash
    set -ex

    # Wait until master has registered the token in SSM
    until TOKEN=$(aws ssm get-parameter \
      --region ${var.aws_region} \
      --name "/${var.env}/k3s/node-token" \
      --with-decryption \
      --query "Parameter.Value" \
      --output text 2>/dev/null); do
      echo "Waiting for node-token..."
      sleep 10
    done

    # Join the cluster
    curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.master.private_ip}:6443 \
      K3S_TOKEN="$TOKEN" sh -
  EOF

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = "${var.env}-k3s-worker-${count.index + 1}"
    Role = "worker"
  })
}

# ------------------------------------------------------------------
# SSM Parameter Store — add permission to IAM role (see iam module)
# ------------------------------------------------------------------
resource "aws_ssm_parameter" "k3s_token_placeholder" {
  name  = "/${var.env}/k3s/node-token"
  type  = "SecureString"
  value = "placeholder"

  lifecycle {
    ignore_changes = [value]
  }

  tags = var.tags
}
