resource "aws_key_pair" "k8s" {
    key_name = "k8s"
    public_key = file("~/onedrive/desktop/ssh_keys/k8s.pub")
}