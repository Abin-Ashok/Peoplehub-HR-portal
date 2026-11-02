resource "aws_sqs_queue" "notifications_dlq" {
  name                      = "${var.project_name}-${var.environment}-notifications-dlq"
  message_retention_seconds = 1209600

  tags = {
    Name        = "${var.project_name}-${var.environment}-notifications-dlq"
    Environment = var.environment
  }
}

resource "aws_sqs_queue" "notifications" {
  name                       = "${var.project_name}-${var.environment}-notifications"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notifications_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-notifications"
    Environment = var.environment
  }
}

resource "aws_iam_role" "lambda_execution" {
  name = "${var.project_name}-${var.environment}-notification-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_sqs_access" {
  name = "${var.project_name}-${var.environment}-notification-sqs-access"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.notifications.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_ses_email_identity" "notification_sender" {
  email = var.sender_email
}

resource "aws_lambda_function" "notifications" {
  function_name    = "${var.project_name}-${var.environment}-notifications"
  role             = aws_iam_role.lambda_execution.arn
  runtime          = "python3.12"
  handler          = "lambda_function.lambda_handler"
  filename         = "${path.module}/notification-lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/notification-lambda.zip")
  timeout          = 10

  environment {
    variables = {
      SENDER_EMAIL = var.sender_email
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-notifications"
    Environment = var.environment
  }
}

resource "aws_lambda_event_source_mapping" "notifications" {
  event_source_arn = aws_sqs_queue.notifications.arn
  function_name    = aws_lambda_function.notifications.arn
  batch_size       = 1
  enabled          = true
}
resource "aws_iam_role" "backend_notifications" {
  name = "${var.project_name}-${var.environment}-backend-notifications-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
}

resource "aws_iam_role_policy" "backend_send_notifications" {
  name = "${var.project_name}-${var.environment}-backend-send-notifications"
  role = aws_iam_role.backend_notifications.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sqs:SendMessage"]
      Resource = aws_sqs_queue.notifications.arn
    }]
  })
}