#------------------------------------------------------------------------------
# VPC Flow Logs
# Enabled via: var.enable_flow_logs
#------------------------------------------------------------------------------

# S3 Bucket for Flow Logs
resource "aws_s3_bucket" "flow_logs" {
  count  = var.enable_flow_logs ? 1 : 0
  bucket = "${var.project_name}-vpc-flow-logs-${var.environment}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-vpc-flow-logs-${var.environment}"
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "flow_logs" {
  count  = var.enable_flow_logs ? 1 : 0
  bucket = aws_s3_bucket.flow_logs[0].id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    expiration {
      days = var.flow_logs_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_versioning" "flow_logs" {
  count  = var.enable_flow_logs ? 1 : 0
  bucket = aws_s3_bucket.flow_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "flow_logs" {
  count  = var.enable_flow_logs ? 1 : 0
  bucket = aws_s3_bucket.flow_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "flow_logs" {
  count  = var.enable_flow_logs ? 1 : 0
  bucket = aws_s3_bucket.flow_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket for Server Access Logs (logs of the flow logs bucket)
resource "aws_s3_bucket" "flow_logs_access_logs" {
  count  = var.enable_flow_logs && var.enable_flow_logs_access_logs ? 1 : 0
  bucket = "${var.project_name}-vpc-flow-logs-access-${var.environment}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-vpc-flow-logs-access-${var.environment}"
  })
}

resource "aws_s3_bucket_logging" "flow_logs" {
  count  = var.enable_flow_logs && var.enable_flow_logs_access_logs ? 1 : 0
  bucket = aws_s3_bucket.flow_logs[0].id

  target_bucket = aws_s3_bucket.flow_logs_access_logs[0].id
  target_prefix = "access-logs/"
}

# VPC Flow Log
resource "aws_flow_log" "this" {
  count                = var.enable_flow_logs ? 1 : 0
  vpc_id               = aws_vpc.this.id
  log_destination      = aws_s3_bucket.flow_logs[0].arn
  log_destination_type = "s3"
  traffic_type         = var.flow_logs_traffic_type

  tags = merge(var.tags, {
    Name = "${var.environment}-vpc-flow-log"
  })
}
