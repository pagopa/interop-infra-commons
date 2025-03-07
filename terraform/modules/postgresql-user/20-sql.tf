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
      ADMIN_CREDENTIALS_SECRET_ARN = var.db_admin_credentials_secret_arn
    }

    command = <<EOT
      #!/bin/bash
      set -euo pipefail
      
      secret_json=$(aws secretsmanager get-secret-value --secret-id $ADMIN_CREDENTIALS_SECRET_ARN --query SecretString --output text)

      ADMIN_USERNAME=$(echo $secret_json | jq -r '.username')
      ADMIN_PASSWORD=$(echo $secret_json | jq -r '.password')

      export PGPASSWORD=$ADMIN_PASSWORD

      envsubst < ${path.module}/scripts/manage_role.sql | \
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
    db_admin_credentials_secret_arn = var.db_admin_credentials_secret_arn
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
      HOST                         = self.input.db_host
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
        envsubst < ${path.module}/scripts/delete_role.sql | \
        psql -h $HOST -U $ADMIN_USERNAME -d $DATABASE
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
      envsubst < ${path.module}/scripts/delete_role.sql | \
      psql -h "$HOST" -U "$ADMIN_USERNAME" -d "$DATABASE" -p "$DATABASE_PORT"
    EOT
  }
}
