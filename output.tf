output "lb_controller_role_arn" {
  description = "AWS Load Balancer Controller IAM Role ARN"
  value       = aws_iam_role.lb_controller_role.arn
}
