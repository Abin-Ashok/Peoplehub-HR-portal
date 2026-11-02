
resource "aws_security_group" "public_alb" {
  name        = "${var.project_name}-${var.environment}-public-alb-sg"
  description = "Public frontend ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-public-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "public_alb_http" {
  security_group_id = aws_security_group.public_alb.id
  description       = "HTTP from internet"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "public_alb_https" {
  security_group_id = aws_security_group.public_alb.id
  description       = "HTTPS from internet"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "frontend" {
  name        = "${var.project_name}-${var.environment}-frontend-sg"
  description = "Frontend EC2"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-frontend-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "frontend_from_public_alb" {
  security_group_id            = aws_security_group.frontend.id
  description                  = "Frontend from public ALB"
  ip_protocol                  = "tcp"
  from_port                    = var.frontend_port
  to_port                      = var.frontend_port
  referenced_security_group_id = aws_security_group.public_alb.id
}

resource "aws_security_group" "internal_alb" {
  name        = "${var.project_name}-${var.environment}-internal-alb-sg"
  description = "Private backend ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-internal-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "internal_alb_from_frontend" {
  security_group_id            = aws_security_group.internal_alb.id
  description                  = "Backend ALB from frontend"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.frontend.id
}

resource "aws_security_group" "jenkins" {
  name        = "${var.project_name}-${var.environment}-jenkins-sg"
  description = "Public Jenkins EC2"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-jenkins-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "jenkins_ssh" {
  count             = var.jenkins_admin_cidr == null ? 0 : 1
  security_group_id = aws_security_group.jenkins.id
  description       = "SSH from trusted administrator IP"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.jenkins_admin_cidr
}

resource "aws_vpc_security_group_ingress_rule" "jenkins_https_ui" {
  count             = var.jenkins_admin_cidr == null ? 0 : 1
  security_group_id = aws_security_group.jenkins.id
  description       = "Jenkins web interface from trusted administrator IP"
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8080
  cidr_ipv4         = var.jenkins_admin_cidr
}

resource "aws_security_group" "rds" {
  count       = var.database_port == null ? 0 : 1
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "RDS database"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_eks" {
  count                        = var.database_port == null ? 0 : 1
  security_group_id            = aws_security_group.rds[0].id
  description                  = "MySQL from EKS cluster security group"
  ip_protocol                  = "tcp"
  from_port                    = var.database_port
  to_port                      = var.database_port
  referenced_security_group_id = var.eks_cluster_security_group_id
}
