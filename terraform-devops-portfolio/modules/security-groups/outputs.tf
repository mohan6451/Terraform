output "master_sg_id" {
  value = aws_security_group.k3s_master.id
}

output "worker_sg_id" {
  value = aws_security_group.k3s_worker.id
}
