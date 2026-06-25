resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "source" {
  # checkov:skip=CKV_AWS_144: "Cross-region replication not needed for student project"
  # checkov:skip=CKV_AWS_145: "KMS encryption not needed for student project"
  # checkov:skip=CKV_AWS_18: "Access logging not needed"
  # checkov:skip=CKV_AWS_21: "Versioning not needed"
  # checkov:skip=CKV_AWS_118: "Not needed"
  bucket        = "${var.bucket_prefix}-source-${random_id.bucket_id.hex}"
  force_destroy = true
}

resource "aws_s3_bucket" "destination" {
  # checkov:skip=CKV_AWS_144: "Cross-region replication not needed"
  # checkov:skip=CKV_AWS_145: "KMS encryption not needed"
  # checkov:skip=CKV_AWS_18: "Access logging not needed"
  # checkov:skip=CKV_AWS_21: "Versioning not needed"
  # checkov:skip=CKV_AWS_118: "Not needed"
  bucket        = "${var.bucket_prefix}-dest-${random_id.bucket_id.hex}"
  force_destroy = true
}
