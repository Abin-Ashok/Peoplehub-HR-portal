
resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  comment             = "${var.project_name}-${var.environment}-frontend"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "frontend-alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # API requests: no caching, forward all required methods.
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "frontend-alb"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS",
      "POST",
      "PUT",
      "PATCH",
      "DELETE"
    ]

    cached_methods = ["GET", "HEAD"]

    cache_policy_id          = "4135ea2d-6df8-44ab-baf2-68738e2966ac"
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
    compress                 = true
  }

  # Frontend static assets.
  default_cache_behavior {
    target_origin_id       = "frontend-alb"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-cloudfront"
    Environment = var.environment
  }
}
