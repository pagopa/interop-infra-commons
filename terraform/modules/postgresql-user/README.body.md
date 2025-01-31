
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

The input sql script in additional_sql_statemets has access to the following environment variables:
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