
resource "aws_efs_file_system" "vpn_automation" {
  performance_mode = "generalPurpose" # Optional: "generalPurpose" or "maxIO"
  throughput_mode  = "bursting"       # Optional: "bursting" or "provisioned"

  tags = {
    Name = format("%s-vpn-automation-efs-%s", var.project_name, var.env)
  }
}

resource "aws_efs_access_point" "vpn_automation" {
  file_system_id = aws_efs_file_system.vpn_automation.id

  posix_user {
    gid = 1000
    uid = 1000
  }
  root_directory {
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 777
    }
    path = "/"
  }

  tags = {
    Name = format("%s-vpn-automation-efs-access-point-%s", var.project_name, var.env)
  }
}

resource "aws_security_group" "efs_vpn_automation" {
  name        = format("efs/%s-vpn-automation-%s", var.project_name, var.env)
  description = format("%s VPN Automation Security group", var.project_name)
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 2049
    to_port         = 2049
    security_groups = toset(var.efs_clients_security_groups_ids)
  }
}

resource "aws_efs_mount_target" "vpn_automation" {
  for_each = { for subnet in var.mount_target_subnets_ids : subnet => subnet }

  file_system_id = aws_efs_file_system.vpn_automation.id
  subnet_id      = each.value

  security_groups = [aws_security_group.efs_vpn_automation.id]
}
