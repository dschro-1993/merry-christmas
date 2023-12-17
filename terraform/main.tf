resource "aws_iam_role" "iam_role" {
  name = "iam-role"
  path = "/service-role/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Principal = {Service = "lambda.amazonaws.com"}
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
      }
    ]
  })
  inline_policy {
    name   = "iam-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Resource = "arn:aws:s3:::${var.bucket_name}/*"
          Action   = ["s3:GetObject"]
          Effect   = "Allow"
        }
      ]
    })
  }
}

resource "aws_iam_role_policy_attachment" "cwl_attachment" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "null_resource" "esbuild" {
  provisioner "local-exec" { command = "npm run build" }
}

data "archive_file" "archive" {
  type        = "zip"
  source_file = "${path.module}/../out/main.js"
  output_path = "${path.module}/zips/deliverooo.zip"
  depends_on  = [null_resource.esbuild]
}

resource "aws_lambda_function" "deliverooo" {
  handler = "main.entrypoint"
  runtime = "nodejs20.x"
  timeout = 10

  filename         = data.archive_file.archive.output_path
  source_code_hash = data.archive_file.archive.output_base64sha256

  function_name = "my-deliverooo"

  environment {
    variables = {
      SOURCE_PHONE_NUMBER = var.source_phone_number
      TARGET_PHONE_NUMBER = var.target_phone_number
      TWILIO_USERNAME     = var.twilio_username
      TWILIO_PASSWORD     = var.twilio_password
      BUCKET_NAME         = var.bucket_name
      OBJECT_NAME         = var.object_name
    }
  }

  role          = aws_iam_role.iam_role.arn
  architectures = ["arm64"] # Use Graviton2

  # tags = {}
}

resource "aws_cloudwatch_event_rule" "merry_christmas" {
  name                = "merry-christmas"
  schedule_expression = "cron(0 15 24 12 ? 2023)" # 4pm => German Time is 1h ahead
}

resource "aws_cloudwatch_event_target" "target" {
  rule  = aws_cloudwatch_event_rule.merry_christmas.name
  arn   = aws_lambda_function.deliverooo.arn
}

resource "aws_lambda_permission" "lambda_permissions" {
  function_name = aws_lambda_function.deliverooo.function_name
  principal     = "events.amazonaws.com"
  action        = "lambda:*"
}
