resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "source" {
  bucket        = "${var.bucket_prefix}-source-${random_id.bucket_id.hex}"
  force_destroy = true
}

resource "aws_s3_bucket" "destination" {
  bucket        = "${var.bucket_prefix}-dest-${random_id.bucket_id.hex}"
  force_destroy = true
}
