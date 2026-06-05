resource "aws_instance" "terraform" {
  ami                    = "ami-0c7217cdde317cfec"
  instance_type          = var.environment == "dev" ? "t3.micro" : "t3.medium"
  vpc_security_group_ids = [aws_security_group.allowAll.id]
  tags = {
    Name      = "machine1"
    terraform = "True"
  }
}
