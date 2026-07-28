
### Execution Requirements

The following tools need to be installed on the local machine were the Terraform Apply will be executed:
* PagoPA VPN
* [AWS CLI](https://aws.amazon.com/it/cli/)
* [jq](https://jqlang.github.io/jq/)
* [psql](https://www.postgresql.org/docs/current/app-psql.html)

### DB Admin credentials

In order to get user credentials, the module input variable "db_admin_credentials_secret_arn" must be specified;
it represents the ARN of the AWS Secrets Manager resource where admin credentials are stored in a JSON format, following this naming convention:

```
{
  "username": "admin_user",
  "password": "admin_password"
}
```

### User credentials secret

The module creates a dedicated AWS Secrets Manager secret for the target DB user.

The stored payload has this structure:

```
{
  "database": "db_name",
  "username": "db_user",
  "password": "generated_password"
}
```

Password generation and secret payload are managed through:

* generated_password_length
* generated_password_use_special_characters
* secret_prefix
* secret_tags
* secret_recovery_window_in_days

The secret value is written using write-only fields on aws_secretsmanager_secret_version.
To force secret payload updates safely, use the secret_string_wo_version input as a monotonic version token (for example: 1, 2, 3, ...).

When you need to rotate credentials, increment secret_string_wo_version and apply again.

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

The input SQL script in additional_sql_statements has access to the following environment variables:
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