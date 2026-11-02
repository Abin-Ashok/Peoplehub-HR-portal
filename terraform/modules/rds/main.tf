resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-${var.environment}-db-subnets"
  description = "Private subnets for the PeopleHub database"
  subnet_ids  = var.private_db_subnet_ids

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnets"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-mysql"

  engine         = "mysql"
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.database_name
  username = var.master_username

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false

  backup_retention_period   = var.backup_retention_period
  copy_tags_to_snapshot     = true
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = "${var.project_name}-${var.environment}-mysql-final"

  auto_minor_version_upgrade = true
  apply_immediately          = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-mysql"
    Environment = var.environment
    Project     = var.project_name
  }

  lifecycle {
    prevent_destroy = true
  }
}


