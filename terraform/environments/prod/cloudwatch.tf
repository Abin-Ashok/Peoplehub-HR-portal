data "aws_iam_policy_document" "cloudwatch_pod_identity_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudwatch_observability" {
  name               = "peoplehub-prod-cloudwatch-observability-role"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_pod_identity_trust.json

  tags = {
    Name        = "peoplehub-prod-cloudwatch-observability-role"
    Project     = "peoplehub"
    Environment = "prod"
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.cloudwatch_observability.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name  = module.eks.cluster_name
  addon_name    = "eks-pod-identity-agent"
  addon_version = "v1.4.1-eksbuild.3"

  depends_on = [
    module.eks
  ]
}

resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name  = module.eks.cluster_name
  addon_name    = "amazon-cloudwatch-observability"
  addon_version = "v7.0.0-eksbuild.1"

  pod_identity_association {
    role_arn        = aws_iam_role.cloudwatch_observability.arn
    service_account = "cloudwatch-agent"
  }

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_iam_role_policy_attachment.cloudwatch_agent
  ]
}