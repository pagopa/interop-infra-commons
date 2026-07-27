<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.100.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.100.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_conditions"></a> [conditions](#input\_conditions) | Conditions for the assume role policy (e.g. sub claim). The aud condition is added automatically. | <pre>list(object({<br/>    test     = string<br/>    variable = string<br/>    values   = list(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_description"></a> [description](#input\_description) | Description for the IAM role | `string` | `""` | no |
| <a name="input_ecr_pull_repositories"></a> [ecr\_pull\_repositories](#input\_ecr\_pull\_repositories) | List of ECR repository name patterns the role can pull from (read-only). | `list(string)` | `[]` | no |
| <a name="input_ecr_push_repositories"></a> [ecr\_push\_repositories](#input\_ecr\_push\_repositories) | List of ECR repository name patterns the role can push and pull (e.g. ['myapp-be*', 'myapp-frontend']). Also grants CreateRepository and lifecycle management. | `list(string)` | `[]` | no |
| <a name="input_managed_policy_arns"></a> [managed\_policy\_arns](#input\_managed\_policy\_arns) | List of managed IAM policy ARNs to attach to the role | `list(string)` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | Name for the IAM role | `string` | n/a | yes |
| <a name="input_statements"></a> [statements](#input\_statements) | Additional IAM policy statements. Combined with ECR statements (if any) into a single inline policy. | <pre>list(object({<br/>    sid       = optional(string)<br/>    effect    = string<br/>    actions   = list(string)<br/>    resources = list(string)<br/>    conditions = optional(list(object({<br/>      test     = string<br/>      variable = string<br/>      values   = list(string)<br/>    })), [])<br/>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | The ARN of the created IAM role |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | The name of the created IAM role |
<!-- END_TF_DOCS -->