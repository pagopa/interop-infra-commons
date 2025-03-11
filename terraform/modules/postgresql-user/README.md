<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.8.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.46.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.46.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.6.3 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_secretsmanager_secret.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [random_password.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [terraform_data.additional_script](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.delete_previous_role](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.delete_role](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.manage_role](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

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
| <a name="input_secret_prefix"></a> [secret\_prefix](#input\_secret\_prefix) | Prefix for the secret that will be created | `string` | n/a | yes |
| <a name="input_secret_recovery_window_in_days"></a> [secret\_recovery\_window\_in\_days](#input\_secret\_recovery\_window\_in\_days) | Number of days that AWS Secrets Manager waits before it can delete the secret | `number` | `0` | no |
| <a name="input_secret_tags"></a> [secret\_tags](#input\_secret\_tags) | Tags to apply to the secret that will be created | `map(string)` | `{}` | no |
| <a name="input_username"></a> [username](#input\_username) | Username to be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_secret_arn"></a> [secret\_arn](#output\_secret\_arn) | User credentials secret ARN |
| <a name="output_secret_id"></a> [secret\_id](#output\_secret\_id) | User credentials secret ID |

### Execution Requirements

The following tools need to be installed on the local machine were the Terraform Apply will be executed:
* PagoPA VPN
* [AWS CLI](https://aws.amazon.com/it/cli/)
* [jq](https://jqlang.github.io/jq/)
* [psql](https://www.postgresql.org/docs/current/app-psql.html)

### DB Admin credentials

In order to get user credentials, the module input variable "db\_admin\_credentials\_secret\_arn" must be specified;
it represents the ARN of the AWS Secrets Manager resource where admin credentials are stored in a JSON format, following this naming convention:

```
{
  "username": "admin_user",
  "password": "admin_password"
}
```

### Usage example

```
module "sql_roles" {
  source       = "./modules/sql-roles"
  db_admin_credentials_secret_arn = "arn:aws:secretsmanager:eu-central-1:000000000000:secret:dbadmincredentials-PDUERn"
  db_host                         = "localhost"
  db_name                         = "db1"
  username                        = "testUser"
  enable_sql_statements           = true
  additional_sql_statements       = <<EOT
        DO \$\$
        BEGIN
        GRANT CREATE ON SCHEMA public TO $USERNAME;
        END
        \$\$;
    EOT
}
```

<b>String Escaping</b>

If the script contains special characters (e.g., $, ", or \), you may need to escape them or use a heredoc (<<EOT) to make it easier to handle.

<b>Environment Variables</b>

The input sql script in additional\_sql\_statemets has access to the following environment variables:
```
# User password
PASSWORD

# User username
USERNAME

# Database name
DATABASE

# Database port
DATABASE_PORT

# Database host
HOST

# DB Admin credentials AWS secret ARN
ADMIN_CREDENTIALS_SECRET_ARN
```
<!-- END_TF_DOCS -->