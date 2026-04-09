# terraform init
# terraform plan 
# terraform apply
# terraform delete

# resource "type_of_resource" "resource_name" {
resource "aws_instance" "terraform"
        ami =
        instance_type =
        tags = {
            Name = "terraform"
            Terraform = "True"

        }
 }

 resource "aws_security_group" "allow_all" {
    name - var.

 }