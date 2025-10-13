/*
  This file configures XML to JSON transformation for S3 objects before forwarding to Observe.

  Flow:
    S3 Bucket (files) -> EventBridge -> Input Transformer Lambda -> S3 Bucket (JSON files under "observe/" prefix) -> Observe

  Notes:
    - Listens to all file uploads in the mock log bucket
    - Automatically detects XML content (by content-type or content inspection)
    - Uses xmltodict to convert XML to JSON format for Observe ingestion
    - Saves transformed files back to the same bucket under "observe/" prefix
    - Skips non-XML files gracefully without failing
    - Simplified setup without VPC, security groups, or dead letter queues
 */

# --------------------------------------------------
# Lambda Package (from ../src/input_transformer directory)
# --------------------------------------------------
# Create a build directory and install dependencies
resource "null_resource" "lambda_dependencies" {
  triggers = {
    requirements = filemd5("${path.module}/../src/input_transformer/requirements.txt")
    source_code  = filemd5("${path.module}/../src/input_transformer/observe_input_transformer.py")
  }

  provisioner "local-exec" {
    command = <<EOF
mkdir -p ${path.module}/builds/lambda_package
cp -r ${path.module}/../src/input_transformer/* ${path.module}/builds/lambda_package/
cd ${path.module}/builds/lambda_package
# Use python3 -m pip for better compatibility across systems
python3 -m pip install -r requirements.txt -t . --no-cache-dir
# Clean up Python cache files that can cause issues
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyc" -delete
EOF
  }
}

data "archive_file" "observe_input_transformer" {
  type        = "zip"
  source_dir  = "${path.module}/builds/lambda_package"
  output_path = "${path.module}/builds/observe_input_transformer.zip"

  depends_on = [null_resource.lambda_dependencies]
}

# --------------------------------------------------
# Input Transformer Lambda Function
# --------------------------------------------------
resource "aws_lambda_function" "observe_input_transformer" {
  filename      = data.archive_file.observe_input_transformer.output_path
  function_name = "${local.resource_prefix}-observe-input-transformer"
  role          = aws_iam_role.observe_input_transformer.arn
  handler       = "observe_input_transformer.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 128

  source_code_hash = data.archive_file.observe_input_transformer.output_base64sha256

  environment {
    variables = {
      OUTPUT_PREFIX                 = "observe"
      OUTPUT_BUCKET                 = "" # Empty means use source bucket
      DELETE_SOURCE_AFTER_TRANSFORM = "false"
    }
  }

  # Run inside VPC private subnets for consistency with other Lambdas
  vpc_config {
    subnet_ids         = module.networking.private_subnet_ids
    security_group_ids = [aws_security_group.observe_input_transformer.id]
  }

  tags = {
    Name = "${local.resource_prefix}-observe-input-transformer"
  }
}

# --------------------------------------------------
# EventBridge Rule for XML File Processing
# --------------------------------------------------
resource "aws_cloudwatch_event_rule" "file_created_for_transform" {
  name        = "${local.resource_prefix}-file-created-to-transform"
  description = "Route file creation events to the input transformer lambda"
  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["Object Created"],
    "detail" : {
      "bucket" : { "name" : ["${aws_s3_bucket.mock_log_storage.bucket}"] }
    }
  })
}

resource "aws_cloudwatch_event_target" "to_input_transformer_lambda" {
  rule      = aws_cloudwatch_event_rule.file_created_for_transform.name
  target_id = "${local.resource_prefix}-input-transformer-lambda"
  arn       = aws_lambda_function.observe_input_transformer.arn
}

resource "aws_lambda_permission" "allow_eventbridge_transformer" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.observe_input_transformer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.file_created_for_transform.arn
}

# --------------------------------------------------
# IAM Role and Policies
# --------------------------------------------------
resource "aws_iam_role" "observe_input_transformer" {
  name = "${local.resource_prefix}-observe-input-transformer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.resource_prefix}-observe-input-transformer-role"
  }
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "observe_input_transformer_basic" {
  role       = aws_iam_role.observe_input_transformer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach VPC execution policy for VPC-enabled Lambda
resource "aws_iam_role_policy_attachment" "observe_input_transformer_vpc" {
  role       = aws_iam_role.observe_input_transformer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# S3 permissions for reading source files and writing transformed files
data "aws_iam_policy_document" "input_transformer_s3" {
  # Allow reading from the entire bucket (for source files)
  statement {
    sid       = "ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.mock_log_storage.arn]
  }

  statement {
    sid       = "GetSourceObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.mock_log_storage.arn}/*"]
  }

  # Allow writing to observe/ prefix and optionally deleting source files
  statement {
    sid    = "PutTransformedObjects"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject" # In case DELETE_SOURCE_AFTER_TRANSFORM is enabled
    ]
    resources = [
      "${aws_s3_bucket.mock_log_storage.arn}/observe/*",
      "${aws_s3_bucket.mock_log_storage.arn}/*" # For potential source deletion
    ]
  }
}

resource "aws_iam_policy" "input_transformer_s3" {
  name   = "${local.resource_prefix}-input-transformer-s3"
  policy = data.aws_iam_policy_document.input_transformer_s3.json
}

resource "aws_iam_role_policy_attachment" "input_transformer_s3" {
  role       = aws_iam_role.observe_input_transformer.name
  policy_arn = aws_iam_policy.input_transformer_s3.arn
}

# --------------------------------------------------
# Security Group for Lambda
# --------------------------------------------------
resource "aws_security_group" "observe_input_transformer" {
  name        = "${local.resource_prefix}-observe-input-transformer-sg"
  description = "Security group for Observe input transformer Lambda"
  vpc_id      = module.networking.vpc_id

  # Egress only SG (Lambda needs outbound HTTPS for S3 access)
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow all outbound traffic"
  }

  tags = {
    Name = "${local.resource_prefix}-observe-input-transformer-sg"
  }
}
