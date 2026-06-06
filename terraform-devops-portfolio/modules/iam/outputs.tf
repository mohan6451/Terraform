output "instance_profile_name" {
  value = aws_iam_instance_profile.ec2_profile.name
}

output "github_actions_role_arn" {
  description = "Paste this into GitHub repo secret AWS_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}
