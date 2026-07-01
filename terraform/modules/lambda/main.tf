data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "ynov-iam_for_lambda_img2pdf"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Project = "ynov-iac-2026"
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = ["${var.source_bucket_arn}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = ["${var.destination_bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda_s3_policy"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/src/handler.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "img2pdf" {
  # checkov:skip=CKV_AWS_115: "Concurrent execution limit not needed"
  # checkov:skip=CKV_AWS_116: "DLQ not needed"
  # checkov:skip=CKV_AWS_117: "VPC not needed"
  # checkov:skip=CKV_AWS_272: "Code-signing not needed"
  # checkov:skip=CKV_AWS_173: "KMS encryption not needed for env vars"
  # checkov:skip=CKV_AWS_50: "X-Ray tracing not needed"
  # checkov:skip=CKV_AWS_283: "Not needed"
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "ynov-img2pdf-converter"
  role          = aws_iam_role.lambda_role.arn
  handler       = "handler.lambda_handler"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  runtime = "python3.11"
  timeout = 30

  environment {
    variables = {
      DEST_BUCKET = var.destination_bucket_id
    }
  }

  tags = {
    Project = "ynov-iac-2026"
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.img2pdf.arn
  principal     = "s3.amazonaws.com"
  source_arn    = var.source_bucket_arn
}
