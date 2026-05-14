<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.100.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.100.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_from_addresses_literal"></a> [allowed\_from\_addresses\_literal](#input\_allowed\_from\_addresses\_literal) | List of addresses that are allowed to be used as 'FROM address' when sending emails. It must contain the exact literals that make each FROM adress (e.g. noreply@dev.interop.pagopa.it) | `list(string)` | `null` | no |
| <a name="input_allowed_from_display_names"></a> [allowed\_from\_display\_names](#input\_allowed\_from\_display\_names) | List of names that are allowed to be used as 'FROM display name' when sending emails | `list(string)` | `null` | no |
| <a name="input_allowed_recipients_literal"></a> [allowed\_recipients\_literal](#input\_allowed\_recipients\_literal) | List of recipients to which is allowd to send emails. It must contain the exact literals that make each single recipient (e.g. example@pagopa.it) | `list(string)` | `null` | no |
| <a name="input_allowed_recipients_regex"></a> [allowed\_recipients\_regex](#input\_allowed\_recipients\_regex) | List of recipients to which is allowd to send emails. It can contain regex with wildcards (e.g. *@pagopa.it) | `list(string)` | `null` | no |
| <a name="input_allowed_source_vpcs_id"></a> [allowed\_source\_vpcs\_id](#input\_allowed\_source\_vpcs\_id) | List of VPC IDs from which it is allowed to send emails | `list(string)` | `null` | no |
| <a name="input_ses_configuration_set_arn"></a> [ses\_configuration\_set\_arn](#input\_ses\_configuration\_set\_arn) | ARN of the SES Configuration set to be used to send emails | `string` | n/a | yes |
| <a name="input_ses_iam_policy_name"></a> [ses\_iam\_policy\_name](#input\_ses\_iam\_policy\_name) | Name of the IAM policy to be created | `string` | n/a | yes |
| <a name="input_ses_identity_arn"></a> [ses\_identity\_arn](#input\_ses\_identity\_arn) | ARN of the SES Identity to be used to send emails | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_policy_arn"></a> [iam\_policy\_arn](#output\_iam\_policy\_arn) | ARN of the IAM policy managed by this module |
<!-- END_TF_DOCS -->