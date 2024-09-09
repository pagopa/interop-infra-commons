output "iam_policy_arn" {
  description = "ARN of the IAM policy managed by this module"
  value       = aws_iam_policy.this.arn
}