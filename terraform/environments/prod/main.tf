
module "networking" {
  source = "../../modules/networking"

  project_name             = var.project_name
  environment              = var.environment
  vpc_cidr                 = var.vpc_cidr
  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  enable_nat_gateway       = var.enable_nat_gateway
}

module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  environment  = var.environment

  vpc_id   = module.networking.vpc_id
  vpc_cidr = var.vpc_cidr

  frontend_port = 80
  backend_port  = 3000
  database_port = 3306

  eks_cluster_security_group_id = module.eks.cluster_security_group_id

  jenkins_admin_cidr = null
}

module "alb" {
  source = "../../modules/alb"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  frontend_port         = 80
}

module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment
}

module "ec2_frontend" {
  source = "../../modules/ec2-frontend"

  project_name          = var.project_name
  environment           = var.environment
  private_subnet_ids    = module.networking.private_app_subnet_ids
  security_group_id     = module.security.frontend_security_group_id
  target_group_arn      = module.alb.frontend_target_group_arn
  instance_profile_name = module.iam.frontend_instance_profile_name

  instance_type    = "t3.small"
  min_size         = 0
  desired_capacity = 0
  max_size         = 2
}

module "eks" {
  source = "../../modules/eks"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_app_subnet_ids

  cluster_version              = "1.33"
  node_instance_types          = ["t3.medium"]
  node_min_size                = 1
  node_desired_size            = 2
  node_max_size                = 3
  endpoint_public_access       = false
  endpoint_public_access_cidrs = []
}

module "rds" {
  source = "../../modules/rds"

  project_name          = var.project_name
  environment           = var.environment
  private_db_subnet_ids = module.networking.private_db_subnet_ids
  security_group_id     = module.security.rds_security_group_id

  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  max_allocated_storage   = 100
  database_name           = "peoplehub"
  master_username         = "peoplehub_admin"
  backup_retention_period = 7
  deletion_protection     = true
  skip_final_snapshot     = false
}

resource "aws_eks_access_entry" "jenkins" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.iam.jenkins_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "jenkins" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.iam.jenkins_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type       = "namespace"
    namespaces = ["peoplehub"]
  }

  depends_on = [
    aws_eks_access_entry.jenkins
  ]
}


resource "aws_eks_pod_identity_association" "load_balancer_controller" {
  cluster_name    = module.eks.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = module.iam.load_balancer_controller_role_arn

  depends_on = [
    aws_eks_addon.pod_identity_agent
  ]
}


resource "aws_vpc_security_group_ingress_rule" "eks_api_from_jenkins" {
  security_group_id            = module.eks.cluster_security_group_id
  referenced_security_group_id = module.security.jenkins_security_group_id

  description = "Allow Jenkins to access the private EKS API"
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
}
