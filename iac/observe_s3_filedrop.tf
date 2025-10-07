/*
  This file configures forwarding of S3 object-created events to Observe via Filedrop.

  Flow:
    TBD

  Notes:
    - The filedrop roles must be informed in the Observe platform UI while creating the Filedrop integration, more info at https://docs.observeinc.com/en/latest/content/data-ingestion/sources/amazon-s3.html
    - Free tier account is limited to us-west-2 region for Filedrop
 */

# --------------------------------------------------
# IAM
# --------------------------------------------------
# resource "aws_iam_role" "observe_filedrop_role" {
#   name = "observe-example-filedrop-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect    = "Allow",
#         Principal = { Service = "lambda.${local.region}.amazonaws.com" },
#         Action    = "sts:AssumeRole"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy" "observe_filedrop_role_policy" {
#   name = "${local.resource_prefix}-filedrop-role-policy"
#   role = aws_iam_role.observe_filedrop_role.id
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect   = "Allow",
#         Action   = "s3:PutObject",
#         Resource = "*"
#         Condition : {
#           StringLike : {
#             "s3:DataAccessPointArn" : var.observe_filedrop_access_point_arn
#           }
#         }
#       }
#     ]
#   })
# }

# --------------------------------------------------
# Observe Filedrop Forwarder
# --------------------------------------------------
module "observe_filedrop" {
  source  = "observeinc/collection/aws//modules/forwarder"
  version = ">= 2.10"

  # name = "${local.resource_prefix}-filedrop"
  name = "${var.project}-filedrop"

  destination = {
    arn    = var.observe_filedrop_access_point_arn
    bucket = var.observe_filedrop_bucket
    prefix = var.observe_filedrop_bucket_prefix
  }

  source_bucket_names = [aws_s3_bucket.mock_log_storage_filedrop.bucket]
}

resource "aws_s3_bucket_notification" "to_sqs" {
  bucket = aws_s3_bucket.mock_log_storage_filedrop.id

  queue {
    queue_arn = module.observe_filedrop.queue_arn
    events    = ["s3:ObjectCreated:*"]
  }
}

