output "lambda_function_arn" {
  value = aws_lambda_function.img2pdf.arn
}

output "lambda_function_name" {
  value = aws_lambda_function.img2pdf.function_name
}
