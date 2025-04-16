locals {
  path_to_scripts = var.redshift_cluster && var.redshift_schema_name_procedures != null ? "${path.module}/scripts/redshift" : "${path.module}/scripts/pgsql"
}

resource "terraform_data" "manage_role" {
  count = var.enable_sql_statements ? 1 : 0

  triggers_replace = [
    var.username,
    var.db_name,
    aws_secretsmanager_secret_version.this.version_id
  ]

  depends_on = [
    aws_secretsmanager_secret_version.this
  ]

  provisioner "local-exec" {
    environment = {
      PASSWORD                     = random_password.this.result
      USERNAME                     = var.username
      DATABASE                     = var.db_name
      DATABASE_PORT                = var.db_port
      HOST                         = var.db_host
      SCHEMA_NAME                  = var.redshift_schema_name_procedures
      ADMIN_CREDENTIALS_SECRET_ARN = var.db_admin_credentials_secret_arn
      GRANT_GROUPS                 = var.grant_redshift_groups == [] ? "" : join(", ", var.grant_redshift_groups) #Pass the groups list as a comma separated string
    }

    command = <<EOT
      #!/bin/bash
      set -euo pipefail
      
      secret_json=$(aws secretsmanager get-secret-value --secret-id $ADMIN_CREDENTIALS_SECRET_ARN --query SecretString --output text)

      ADMIN_USERNAME=$(echo $secret_json | jq -r '.username')
      ADMIN_PASSWORD=$(echo $secret_json | jq -r '.password')

      export PGPASSWORD=$ADMIN_PASSWORD

      envsubst < ${local.path_to_scripts}/manage_role.sql | \
      psql --host "$HOST" --username "$ADMIN_USERNAME" --port "$DATABASE_PORT" --dbname "$DATABASE"
    EOT
  }
}

resource "terraform_data" "additional_script" {
  count = var.enable_sql_statements && var.additional_sql_statements != null ? 1 : 0

  triggers_replace = [
    var.username,
    var.db_name,
    var.additional_sql_statements
  ]

  depends_on = [
    terraform_data.manage_role
  ]

  provisioner "local-exec" {
    environment = {
      PASSWORD                     = random_password.this.result
      USERNAME                     = var.username
      DATABASE                     = var.db_name
      DATABASE_PORT                = var.db_port
      HOST                         = var.db_host
      SCHEMA_NAME                  = var.redshift_schema_name_procedures
      ADMIN_CREDENTIALS_SECRET_ARN = var.db_admin_credentials_secret_arn
    }

    command = <<EOT
      #!/bin/bash
      set -euo pipefail
      
      secret_json=$(aws secretsmanager get-secret-value --secret-id $ADMIN_CREDENTIALS_SECRET_ARN --query SecretString --output text)

      ADMIN_USERNAME=$(echo $secret_json | jq -r '.username')
      ADMIN_PASSWORD=$(echo $secret_json | jq -r '.password')

      export PGPASSWORD=$ADMIN_PASSWORD

      psql -h "$HOST" -U "$ADMIN_USERNAME" -d "$DATABASE" -p "$DATABASE_PORT" -c "${var.additional_sql_statements}"
    EOT
  }
}

resource "terraform_data" "delete_previous_role" {
  count = var.enable_sql_statements ? 1 : 0

  input = {
    username                        = var.username
    db_name                         = var.db_name
    db_host                         = var.db_host
    db_port                         = var.db_port
    db_admin_credentials_secret_arn = var.db_admin_credentials_secret_arn
    redshift_schema_name            = var.redshift_schema_name_procedures
    path_to_scripts                 = local.path_to_scripts
  }

  triggers_replace = [
    var.username
  ]

  depends_on = [
    aws_secretsmanager_secret_version.this
  ]

  provisioner "local-exec" {
    environment = {
      DATABASE                     = self.input.db_name
      DATABASE_PORT                = self.input.db_port
      HOST                         = self.input.db_host
      SCHEMA_NAME                  = self.input.redshift_schema_name
      ADMIN_CREDENTIALS_SECRET_ARN = self.input.db_admin_credentials_secret_arn
      USERNAME                     = self.triggers_replace[0]
      CURRENT_USERNAME             = self.input.username
    }

    command = <<EOT
      #!/bin/bash
      set -euo pipefail
      
      if [[ "$USERNAME" != "$CURRENT_USERNAME" ]]; then
        secret_json=$(aws secretsmanager get-secret-value --secret-id $ADMIN_CREDENTIALS_SECRET_ARN --query SecretString --output text)

        ADMIN_USERNAME=$(echo $secret_json | jq -r '.username')
        ADMIN_PASSWORD=$(echo $secret_json | jq -r '.password')

        export PGPASSWORD=$ADMIN_PASSWORD
        export ADMIN_USERNAME=$ADMIN_USERNAME
        
        echo "Deleting old role $USERNAME from database $DATABASE"
        envsubst < ${self.input.path_to_scripts}/delete_role.sql | \
        psql -h $HOST -U $ADMIN_USERNAME -d $DATABASE -p $DATABASE_PORT
      fi
    EOT
  }
}

resource "terraform_data" "delete_role" {
  count = var.enable_sql_statements ? 1 : 0

  input = {
    username                        = var.username
    db_name                         = var.db_name
    db_host                         = var.db_host
    db_port                         = var.db_port
    db_admin_credentials_secret_arn = var.db_admin_credentials_secret_arn
    redshift_schema_name            = var.redshift_schema_name_procedures
    path_to_scripts                 = local.path_to_scripts
  }

  triggers_replace = [
    aws_secretsmanager_secret.this.id
  ]

  depends_on = [
    aws_secretsmanager_secret.this
  ]

  provisioner "local-exec" {
    when = destroy

    environment = {
      USERNAME                     = self.input.username
      DATABASE                     = self.input.db_name
      DATABASE_PORT                = self.input.db_port
      HOST                         = self.input.db_host
      SCHEMA_NAME                  = self.input.redshift_schema_name
      ADMIN_CREDENTIALS_SECRET_ARN = self.input.db_admin_credentials_secret_arn
    }

    command = <<EOT
      #!/bin/bash
      set -euo pipefail
      
      secret_json=$(aws secretsmanager get-secret-value --secret-id $ADMIN_CREDENTIALS_SECRET_ARN --query SecretString --output text)

      ADMIN_USERNAME=$(echo $secret_json | jq -r '.username')
      ADMIN_PASSWORD=$(echo $secret_json | jq -r '.password')

      export PGPASSWORD=$ADMIN_PASSWORD
      export ADMIN_USERNAME=$ADMIN_USERNAME
      
      echo "Deleting role $USERNAME from database $DATABASE"
      envsubst < ${self.input.path_to_scripts}/delete_role.sql | \
      psql -h "$HOST" -U "$ADMIN_USERNAME" -d "$DATABASE" -p "$DATABASE_PORT"
    EOT
  }
}
