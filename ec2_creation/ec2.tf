resource "aws_instance" "terraform" {
  ami                    = "ami-0b6d9d3d33ba97d99"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.allowAll.id]
  key_name = aws_key_pair.k8s.key_name
  tags = {
    Name      = "machine1"
    terraform = "True"
  }
}
