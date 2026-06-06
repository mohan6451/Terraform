output "master_public_ip" {
  description = "SSH into master: ssh -i ~/.ssh/k3s-key ec2-user@<this IP>"
  value       = aws_instance.master.public_ip
}

output "master_private_ip" {
  value = aws_instance.master.private_ip
}

output "worker_public_ips" {
  value = aws_instance.worker[*].public_ip
}

output "kubeconfig_command" {
  description = "Run this after apply to configure kubectl"
  value       = "scp -i ~/.ssh/k3s-key ec2-user@${aws_instance.master.public_ip}:/etc/rancher/k3s/k3s.yaml ~/.kube/config && sed -i 's/127.0.0.1/${aws_instance.master.public_ip}/g' ~/.kube/config"
}
