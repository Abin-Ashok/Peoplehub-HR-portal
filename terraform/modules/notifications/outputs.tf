output "queue_url" {
  description = "SQS notification queue URL"
  value       = aws_sqs_queue.notifications.url
}

output "queue_arn" {
  description = "SQS notification queue ARN"
  value       = aws_sqs_queue.notifications.arn
}

output "dead_letter_queue_url" {
  description = "SQS dead-letter queue URL"
  value       = aws_sqs_queue.notifications_dlq.url
}

output "sender_email" {
  description = "Configured SES sender email address"
  value       = aws_ses_email_identity.notification_sender.email
}
output "backend_notifications_role_arn" {
  description = "IAM role ARN for the backend to send notification messages"
  value       = aws_iam_role.backend_notifications.arn
}

output "notification_queue_url_for_backend" {
  description = "SQS queue URL for backend notification publishing"
  value       = aws_sqs_queue.notifications.url
}