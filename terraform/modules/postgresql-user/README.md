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
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_secretsmanager_secret.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [terraform_data.additional_script](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.delete_previous_role](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.delete_role](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.manage_role](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_secretsmanager_random_password.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_random_password) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_sql_statements"></a> [additional\_sql\_statements](#input\_additional\_sql\_statements) | Optional SQL inline script executed after user role creation/update | `string` | `null` | no |
| <a name="input_db_admin_credentials_secret_arn"></a> [db\_admin\_credentials\_secret\_arn](#input\_db\_admin\_credentials\_secret\_arn) | DB admin secret ARN. Expected JSON with fields 'username', 'password' | `string` | n/a | yes |
| <a name="input_db_host"></a> [db\_host](#input\_db\_host) | Database host | `string` | n/a | yes |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Database name | `string` | n/a | yes |
| <a name="input_db_port"></a> [db\_port](#input\_db\_port) | Database port | `number` | `5432` | no |
| <a name="input_enable_sql_statements"></a> [enable\_sql\_statements](#input\_enable\_sql\_statements) | Enable SQL scripts execution | `bool` | `true` | no |
| <a name="input_generated_password_length"></a> [generated\_password\_length](#input\_generated\_password\_length) | Length of the generated password for the user | `number` | n/a | yes |
| <a name="input_generated_password_use_special_characters"></a> [generated\_password\_use\_special\_characters](#input\_generated\_password\_use\_special\_characters) | Enable special characters in the generated password for the user | `bool` | `false` | no |
| <a name="input_grant_redshift_groups"></a> [grant\_redshift\_groups](#input\_grant\_redshift\_groups) | List of groups the user must be added to. If a group does not exist, it will be created. Specifically for Redshift | `list(string)` | `[]` | no |
| <a name="input_redshift_cluster"></a> [redshift\_cluster](#input\_redshift\_cluster) | Use Redshift-compatible SQL scripts | `bool` | `false` | no |
| <a name="input_redshift_schema_name_procedures"></a> [redshift\_schema\_name\_procedures](#input\_redshift\_schema\_name\_procedures) | Redshift schema name in which to create stored procedures | `string` | `"terraform_postgresql_user_module"` | no |
| <a name="input_secret_prefix"></a> [secret\_prefix](#input\_secret\_prefix) | Prefix for the secret that will be created | `string` | n/a | yes |
| <a name="input_secret_recovery_window_in_days"></a> [secret\_recovery\_window\_in\_days](#input\_secret\_recovery\_window\_in\_days) | Number of days that AWS Secrets Manager waits before it can delete the secret | `number` | `0` | no |
| <a name="input_secret_tags"></a> [secret\_tags](#input\_secret\_tags) | Tags to apply to the secret that will be created | `map(string)` | `{}` | no |
| <a name="input_username"></a> [username](#input\_username) | Username to be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_secret_arn"></a> [secret\_arn](#output\_secret\_arn) | User credentials secret ARN |
| <a name="output_secret_id"></a> [secret\_id](#output\_secret\_id) | User credentials secret ID |
| <a name="output_secret_name"></a> [secret\_name](#output\_secret\_name) | User credentials secret name |
<!-- END_TF_DOCS -->