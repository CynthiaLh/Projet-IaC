variable "source_bucket_id" {
  type        = string
  description = "ID of the source S3 bucket"
}

variable "source_bucket_arn" {
  type        = string
  description = "ARN of the source S3 bucket"
}

variable "destination_bucket_id" {
  type        = string
  description = "ID of the destination S3 bucket"
}

variable "destination_bucket_arn" {
  type        = string
  description = "ARN of the destination S3 bucket"
}
