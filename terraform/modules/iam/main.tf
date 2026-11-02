
resource "aws_iam_role" "frontend_ec2" {
  name               = "${var.project_name}-${var.environment}-frontend-ec2-role"
  assume_role_policy = file("${path.module}/ec2-trust-policy.json")

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-ec2-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "frontend_ecr_read" {
  role       = aws_iam_role.frontend_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "frontend_ec2" {
  name = "${var.project_name}-${var.environment}-frontend-instance-profile"
  role = aws_iam_role.frontend_ec2.name

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-instance-profile"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role" "jenkins" {
  name               = "${var.project_name}-${var.environment}-jenkins-deploy-role"
  assume_role_policy = file("${path.module}/ec2-trust-policy.json")

  tags = {
    Name        = "${var.project_name}-${var.environment}-jenkins-deploy-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.project_name}-${var.environment}-jenkins-instance-profile"
  role = aws_iam_role.jenkins.name

  tags = {
    Name        = "${var.project_name}-${var.environment}-jenkins-instance-profile"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy" "jenkins_deploy" {
  name = "${var.project_name}-${var.environment}-jenkins-deploy-policy"
  role = aws_iam_role.jenkins.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ECRAuthentication"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "PushPeopleHubImages"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = [
          "arn:aws:ecr:ap-south-1:555509860178:repository/peoplehub-frontend",
          "arn:aws:ecr:ap-south-1:555509860178:repository/peoplehub-backend"
        ]
      },
      {
        Sid    = "RefreshFrontendInstances"
        Effect = "Allow"
        Action = [
          "autoscaling:StartInstanceRefresh",
          "autoscaling:DescribeInstanceRefreshes",
          "autoscaling:DescribeAutoScalingGroups"
        ]
        Resource = "*"
      },
      {
        Sid      = "DescribePeopleHubEKS"
        Effect   = "Allow"
        Action   = ["eks:DescribeCluster"]
        Resource = "arn:aws:eks:ap-south-1:555509860178:cluster/peoplehub-prod-eks"
      }
    ]
  })
}

# IAM role used by the AWS Load Balancer Controller through EKS Pod Identity.
data "aws_iam_policy_document" "load_balancer_controller_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "load_balancer_controller" {
  name               = "${var.project_name}-${var.environment}-aws-load-balancer-controller-role"
  assume_role_policy = data.aws_iam_policy_document.load_balancer_controller_trust.json

  tags = {
    Name        = "${var.project_name}-${var.environment}-aws-load-balancer-controller-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_policy" "load_balancer_controller" {
  name        = "${var.project_name}-${var.environment}-aws-load-balancer-controller-policy"
  description = "Permissions for the AWS Load Balancer Controller"
  policy      = file("${path.module}/aws-load-balancer-controller-policy.json")

  tags = {
    Name        = "${var.project_name}-${var.environment}-aws-load-balancer-controller-policy"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "load_balancer_controller" {
  role       = aws_iam_role.load_balancer_controller.name
  policy_arn = aws_iam_policy.load_balancer_controller.arn
}
