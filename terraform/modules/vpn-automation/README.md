<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.46 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.46 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpn_automation_bucket"></a> [vpn\_automation\_bucket](#module\_vpn\_automation\_bucket) | terraform-aws-modules/s3-bucket/aws | 3.15.1 |

## Resources

| Name | Type |
|------|------|
| [aws_ecr_lifecycle_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository_policy.vpn_clients_ecr_retrieval](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |
| [aws_efs_access_point.vpn_automation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_access_point) | resource |
| [aws_efs_file_system.vpn_automation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system) | resource |
| [aws_efs_mount_target.vpn_automation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target) | resource |
| [aws_iam_policy.vpn_automation_step_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.vpn_clients_s3_bucket_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.vpn_clients_vpn_endpoint_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.vpn_automation_step_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.vpn_clients_diff_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.vpn_clients_updater_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_lambda_function.vpn_clients_diff_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.vpn_clients_updater_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_security_group.efs_vpn_automation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.this_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_sfn_state_machine.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sfn_state_machine) | resource |
| [aws_ec2_managed_prefix_list.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_managed_prefix_list) | data source |
| [aws_iam_policy_document.lambda_ecr_image_retrieval_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vpn_clients_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_client_vpn_endpoint_arn"></a> [client\_vpn\_endpoint\_arn](#input\_client\_vpn\_endpoint\_arn) | Client VPN Endpoint ARN | `string` | n/a | yes |
| <a name="input_clients_updater_image_tag"></a> [clients\_updater\_image\_tag](#input\_clients\_updater\_image\_tag) | Image tag for vpn-clients-updater repository | `string` | n/a | yes |
| <a name="input_efs_clients_security_groups_ids"></a> [efs\_clients\_security\_groups\_ids](#input\_efs\_clients\_security\_groups\_ids) | AWS EFS Subnets ids | `set(string)` | n/a | yes |
| <a name="input_efs_pki_directory"></a> [efs\_pki\_directory](#input\_efs\_pki\_directory) | EASYRSA EFS pki directory | `string` | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | Environment name | `string` | n/a | yes |
| <a name="input_lambda_function_subnets_ids"></a> [lambda\_function\_subnets\_ids](#input\_lambda\_function\_subnets\_ids) | AWS Lambda Subnets ids | `set(string)` | n/a | yes |
| <a name="input_mount_target_subnets_ids"></a> [mount\_target\_subnets\_ids](#input\_mount\_target\_subnets\_ids) | AWS EFS Mount Target Subnets ids | `set(string)` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project | `string` | n/a | yes |
| <a name="input_ses_configuration_set_name"></a> [ses\_configuration\_set\_name](#input\_ses\_configuration\_set\_name) | SES Configuration set name | `string` | n/a | yes |
| <a name="input_ses_from_address"></a> [ses\_from\_address](#input\_ses\_from\_address) | SES From Address | `string` | n/a | yes |
| <a name="input_ses_from_display_name"></a> [ses\_from\_display\_name](#input\_ses\_from\_display\_name) | SES From Display Name | `string` | n/a | yes |
| <a name="input_ses_mail_subject"></a> [ses\_mail\_subject](#input\_ses\_mail\_subject) | SES Email Subject | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC id | `string` | n/a | yes |
| <a name="input_vpn_endpoint_id"></a> [vpn\_endpoint\_id](#input\_vpn\_endpoint\_id) | VPN Endpoint id | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->