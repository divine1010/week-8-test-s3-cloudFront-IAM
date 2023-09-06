provider "aws" {
  region = "us-east-1"
  access_key = ""
  secret_key = ""
}

# Create S3 bucket for logging
resource "aws_s3_bucket" "my_logs_bucket" {
  bucket = "my-logs-bucket-dinesh"
}

# Create an S3 bucket with versioning and public read access
resource "aws_s3_bucket" "my_devops_internship_bucket" {
  bucket = "my-devops-internship-bucket-dinesh.mounickraj.com"

  versioning {
    enabled = true
  }

  # Configure logging to another S3 bucket
  logging {
    target_bucket = aws_s3_bucket.my_logs_bucket.id
  }
}

resource "aws_s3_bucket_ownership_controls" "ownership_control" {
  bucket = aws_s3_bucket.my_devops_internship_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_ownership_controls" "ownership_control_log" {
  bucket = aws_s3_bucket.my_logs_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.my_devops_internship_bucket.id
  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_public_access_block" "public_access_log" {
  bucket = aws_s3_bucket.my_logs_bucket.id
  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.ownership_control,
    aws_s3_bucket_public_access_block.public_access,
  ]

  bucket = aws_s3_bucket.my_devops_internship_bucket.id
  acl = "public-read"
}

resource "aws_s3_bucket_acl" "bucket_acl_log" {
  depends_on = [
    aws_s3_bucket_ownership_controls.ownership_control_log,
    aws_s3_bucket_public_access_block.public_access_log,
  ]

  bucket = aws_s3_bucket.my_logs_bucket.id
  acl = "public-read"
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.my_devops_internship_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = ["s3:GetObject"],
        Effect = "Allow",
        Principal = "*",
        Resource = "${aws_s3_bucket.my_devops_internship_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "bucket_policy_log" {
  bucket = aws_s3_bucket.my_logs_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = ["s3:PutObject"],
        Effect = "Allow",
        Principal = "*",
        Resource = "${aws_s3_bucket.my_logs_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_object" "index_html" {
  bucket = aws_s3_bucket.my_devops_internship_bucket.id
  key    = "index.html"
  source = "index.html"
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "error_html" {
  bucket = aws_s3_bucket.my_devops_internship_bucket.id
  key    = "error.html"
  source = "error.html"
  content_type = "text/html"
}

resource "aws_s3_bucket_website_configuration" "website_configuration" {
  bucket = aws_s3_bucket.my_devops_internship_bucket.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
  depends_on = [ aws_s3_bucket_acl.bucket_acl ]
}

resource "aws_acm_certificate" "aws_acm_cert" {
  domain_name       = "my-devops-internship-bucket-dinesh.mounickraj.com" 
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Create a CloudFront distribution
resource "aws_cloudfront_distribution" "my_cloudfront_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.my_devops_internship_bucket.bucket}.s3.us-east-1.amazonaws.com"
    origin_id   = "S3-origin"
  }

  enabled = true
  is_ipv6_enabled     = true
  default_root_object = "index.html" 

  # Configure HTTPS for secure content delivery
  aliases = ["my-devops-internship-bucket-dinesh.mounickraj.com"]

  default_cache_behavior {
    allowed_methods      = ["GET", "HEAD", "OPTIONS"]
    cached_methods       = ["GET", "HEAD"]
    target_origin_id     = "S3-origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

# Implement logging to the S3 bucket created earlier
#  logging_config {
#    bucket = aws_s3_bucket.my_logs_bucket.id 
#    include_cookies = false
#    prefix = "distribution-logs/"
#  }

  # Configure custom error responses
  custom_error_response {
    error_code          = 404
    response_code       = 200
    response_page_path  = "/error.html" 
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.aws_acm_cert.arn
    ssl_support_method = "sni-only"
  }
}

# IAM Role for CloudFront and S3 Access
resource "aws_iam_role" "cloudfront_s3_role" {
  name = "cloudfront-s3-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = ["cloudfront.amazonaws.com","s3.amazonaws.com"]
        }
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/CloudFrontFullAccess",
  ]
}

# IAM Role for EC2 Access
resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
  ]
}
