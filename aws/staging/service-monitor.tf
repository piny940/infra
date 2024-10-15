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
  description   = "Service monitor of staging home cluster"
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
resource "aws_iam_role" "event_bridge" {
  name = "stg-event-bridge"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "scheduler.amazonaws.com"
        },
        "Sid" : "",
        "Effect" : "Allow"
      }
    ]
  })
}

# Event Bridge
resource "aws_iam_role_policy" "event_bridge" {
  name   = "stg-service-monitor-event-bridge"
  role   = aws_iam_role.event_bridge.name
  policy = data.aws_iam_policy_document.event_bridge.json
}
data "aws_iam_policy_document" "event_bridge" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
    ]

    resources = [
      aws_lambda_function.test_lambda.arn,
    ]
  }
}
resource "aws_scheduler_schedule" "service-monitor" {
  name                         = "stg-service-monitor"
  schedule_expression          = "cron(0/5 * * * ? *)"
  schedule_expression_timezone = "Asia/Tokyo"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.service-monitor.arn
    role_arn = aws_iam_role.event_bridge.arn
  }
}
