output "master_public_ip" {
  value = module.ec2.master_public_ip
}

output "worker_public_ips" {
  value = module.ec2.worker_public_ips
}

output "kubeconfig_command" {
  description = "Run this to configure kubectl after apply"
  value       = module.ec2.kubeconfig_command
}

output "github_actions_role_arn" {
  description = "Add this as GitHub secret AWS_ROLE_ARN"
  value       = module.iam.github_actions_role_arn
}
