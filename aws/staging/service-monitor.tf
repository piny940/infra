resource "aws_iam_role" "service-monitor" {
  name = "stg-service-monitor"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}
data "archive_file" "dummy" {
  type        = "zip"
  output_path = "${path.module}/package.zip"

  source {
    content  = "dummy"
    filename = "dummy.txt"
  }
}
resource "aws_lambda_function" "service-monitor" {
  function_name = "stg-service-monitor"
  role          = aws_iam_role.service-monitor.arn
  handler       = "index.handler"
  runtime       = "python3.12"
  architectures = ["x86_64"]
  filename      = data.archive_file.dummy.output_path

  environment {
    variables = {
      HEALTH_CHECK_URL = ""
      SLACK_API_TOKEN  = ""
      SLACK_CHANNEL    = local.slack_channel
    }
  }
}
