resource "aws_instance" "terraform" {
  ami                    = var.ami_id
  instance_type          = var.image
  vpc_security_group_ids = [aws_security_group.allowAll.id]
  tags = var.ec2_tags
}
