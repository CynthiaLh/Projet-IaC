module "s3" {
  source        = "./modules/s3"
  bucket_prefix = "ynov-img2pdf"
}

module "lambda" {
  source = "./modules/lambda"

  source_bucket_id       = module.s3.source_bucket_id
  source_bucket_arn      = module.s3.source_bucket_arn
  destination_bucket_id  = module.s3.destination_bucket_id
  destination_bucket_arn = module.s3.destination_bucket_arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = module.s3.source_bucket_id

  lambda_function {
    lambda_function_arn = module.lambda.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [module.lambda] # Wait for lambda permissions
}
