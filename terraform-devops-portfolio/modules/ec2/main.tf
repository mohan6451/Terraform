# ------------------------------------------------------------------
# Fetch latest Ubuntu 24.04 LTS AMI
# ------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's official AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
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
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_ids[0]
  vpc_security_group_ids = [var.master_sg_id]
  key_name               = aws_key_pair.k3s.key_name
  iam_instance_profile   = var.instance_profile_name

  user_data = templatefile("${path.module}/scripts/master.sh", {
    aws_region = var.aws_region
    env        = var.env
  })

  root_block_device {
    volume_type = "gp3"
    volume_size = 40
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
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_ids[count.index % length(var.public_subnet_ids)]
  vpc_security_group_ids = [var.worker_sg_id]
  key_name               = aws_key_pair.k3s.key_name
  iam_instance_profile   = var.instance_profile_name

  # Workers wait for master EC2 to exist before booting
  depends_on = [aws_instance.master]

  user_data = templatefile("${path.module}/scripts/worker.sh", {
    aws_region        = var.aws_region
    env               = var.env
    master_private_ip = aws_instance.master.private_ip
  })

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = "${var.env}-k3s-worker-${count.index + 1}"
    Role = "worker"
  })
}

# ------------------------------------------------------------------
# SSM Parameter Store placeholder — master overwrites this at runtime
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
