resource "aws_iam_policy" "vpn_automation_step_function" {
  name        = format("%s-vpn-automation-step-function-%s", var.project_name, var.env)
  description = format("%s Policy for Step Function to execute Lambda", var.project_name)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "lambda:InvokeFunction"
        Resource = [
          aws_lambda_function.vpn_clients_diff_lambda.arn,
          aws_lambda_function.vpn_clients_updater_lambda.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "vpn_automation_step_function" {
  name = format("%s-vpn-automation-step-function-%s", var.project_name, var.env)

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [aws_iam_policy.vpn_automation_step_function.arn]
}

resource "aws_sfn_state_machine" "this" {
  name     = format("%s-vpn-automation-step-function-%s", var.project_name, var.env)
  role_arn = aws_iam_role.vpn_automation_step_function.arn

  definition = templatefile("${path.module}/16.1-step-function-def.tftpl.json", {
    env                                      = var.env,
    project_name                             = var.project_name,
    vpn_clients_diff_lambda_arn              = aws_lambda_function.vpn_clients_diff_lambda.arn,
    vpn_clients_diff_lambda_version          = aws_lambda_function.vpn_clients_diff_lambda.version,
    vpn_clients_create_action_lambda_arn     = aws_lambda_function.vpn_clients_updater_lambda.arn
    vpn_clients_create_action_lambda_version = aws_lambda_function.vpn_clients_updater_lambda.version,
    vpn_clients_revoke_action_lambda_arn     = aws_lambda_function.vpn_clients_updater_lambda.arn
    vpn_clients_revoke_action_lambda_version = aws_lambda_function.vpn_clients_updater_lambda.version,
  })
}
